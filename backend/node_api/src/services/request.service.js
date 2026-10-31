/**
 * src/services/request.service.js
 *
 * Core workflow engine for UniFlow.
 * Manages request lifecycle, runtime step progression, validation, and audit logging.
 */

import mongoose from 'mongoose';
import Request, { REQUEST_STATUSES, STEP_STATUSES } from '../models/Request.js';
import Service from '../models/Service.js';
import Workflow from '../models/Workflow.js';
import User from '../models/User.js';
import { AppError } from '../utils/AppError.js';
import { createNotification } from './notification.service.js';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function isTerminalStatus(status) {
  return ['COMPLETED', 'BOOKING_CONFIRMED', 'REJECTED'].includes(status);
}

// ─── Service Methods ──────────────────────────────────────────────────────────

/**
 * Submit a new student request.
 */
export async function createRequest({ studentId, serviceId, formData = {} }) {
  const isObjectId = mongoose.Types.ObjectId.isValid(serviceId) && String(new mongoose.Types.ObjectId(serviceId)) === serviceId;
  const serviceQuery = isObjectId ? { _id: serviceId } : { slug: serviceId };

  const service = await Service.findOne({ ...serviceQuery, isActive: true }).populate('workflow');
  if (!service) {
    throw AppError.notFound(`Service not found or is currently inactive: ${serviceId}`);
  }

  const workflow = service.workflow;
  if (!workflow || !workflow.steps || workflow.steps.length === 0) {
    throw AppError.badRequest('Service does not have an active workflow configured.');
  }

  // Initialise runtime steps from workflow definition
  const runtimeSteps = workflow.steps.map((step) => ({
    stepIndex: step.stepIndex,
    name: step.name,
    assignedRole: step.assignedRole,
    isPaymentStep: Boolean(step.isPaymentStep),
    status: STEP_STATUSES.PENDING,
    actor: null,
    comment: null,
    actionedAt: null,
  }));

  const initialStatus = workflow.steps[0].pendingStatus || 'SUBMITTED';

  const newRequest = new Request({
    student: studentId,
    service: service._id,
    institution: service.institution,
    workflow: workflow._id,
    workflowVersion: workflow.version,
    status: initialStatus,
    currentStepIndex: 0,
    formData,
    runtimeSteps,
    auditLog: [
      {
        timestamp: new Date(),
        actor: studentId,
        action: 'SUBMITTED',
        stepIndex: 0,
        previousStatus: null,
        newStatus: initialStatus,
        comment: 'Request submitted by student.',
      },
    ],
  });

  await newRequest.save();

  // Create submission notification for the student
  await createNotification({
    recipientId: studentId,
    requestId: newRequest._id,
    title: 'Request Submitted',
    message: `Your request for ${service.name} (${newRequest.requestNumber}) has been submitted successfully.`,
    type: 'INFO',
  });

  return getRequestById(newRequest._id.toString(), { id: studentId, role: 'student' });
}

/**
 * Get request by ID with full relations and access control.
 */
export async function getRequestById(requestId, user) {
  if (!mongoose.Types.ObjectId.isValid(requestId)) {
    throw AppError.notFound(`Request not found: ${requestId}`);
  }

  const request = await Request.findById(requestId)
    .populate('student', 'name email studentId department')
    .populate({
      path: 'service',
      select: 'name slug description category estimatedDays responsibleDepartment formFields',
      populate: { path: 'responsibleDepartment', select: 'name code' },
    })
    .populate('institution', 'name code')
    .populate('runtimeSteps.actor', 'name email role')
    .populate('auditLog.actor', 'name email role');

  if (!request) {
    throw AppError.notFound(`Request not found: ${requestId}`);
  }

  // Access rule: students may only view their own requests
  if (user.role === 'student' && request.student._id.toString() !== user.id) {
    throw AppError.forbidden('You do not have permission to view this request.');
  }

  return request;
}

/**
 * List requests with role-based filtering and pagination.
 */
export async function listRequests({ user, status, serviceId, page = 1, limit = 20 }) {
  const query = {};

  if (user.role === 'student') {
    query.student = user.id;
  }

  if (status) {
    query.status = status;
  }

  if (serviceId) {
    if (mongoose.Types.ObjectId.isValid(serviceId)) {
      query.service = serviceId;
    } else {
      const s = await Service.findOne({ slug: serviceId });
      if (s) query.service = s._id;
    }
  }

  const skip = (Math.max(1, page) - 1) * limit;

  const [requests, total] = await Promise.all([
    Request.find(query)
      .populate('student', 'name email studentId')
      .populate('service', 'name slug category estimatedDays')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Request.countDocuments(query),
  ]);

  return {
    items: requests,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      pages: Math.ceil(total / limit) || 1,
    },
  };
}

/**
 * Action a workflow step (Approve or Reject) by staff or admin.
 */
export async function actionStep({ requestId, stepIndex, action, actorUser, comment = '' }) {
  if (!['APPROVE', 'REJECT'].includes(action)) {
    throw AppError.badRequest(`Invalid action: ${action}. Must be APPROVE or REJECT.`);
  }

  const request = await Request.findById(requestId).populate('service');
  if (!request) {
    throw AppError.notFound(`Request not found: ${requestId}`);
  }

  // Terminal check
  if (isTerminalStatus(request.status)) {
    throw AppError.badRequest(
      `Cannot action request ${request.requestNumber} because it is already in a terminal status (${request.status}).`,
      'INVALID_TRANSITION'
    );
  }

  const numericStepIndex = Number(stepIndex);
  if (numericStepIndex !== request.currentStepIndex) {
    throw AppError.badRequest(
      `Step ${numericStepIndex} cannot be actioned. The current active step is ${request.currentStepIndex}.`,
      'INVALID_TRANSITION'
    );
  }

  const currentStep = request.runtimeSteps[numericStepIndex];
  if (!currentStep) {
    throw AppError.notFound(`Step definition not found at index ${numericStepIndex}`);
  }

  // Rule 5: A student must NEVER be able to approve/action their own requests
  if (request.student.toString() === actorUser.id) {
    throw AppError.forbidden('A student cannot approve or action their own request.');
  }

  // Role authorization
  if (actorUser.role !== 'admin' && actorUser.role !== currentStep.assignedRole) {
    throw AppError.forbidden(`This step requires the "${currentStep.assignedRole}" role.`);
  }

  const previousStatus = request.status;

  if (action === 'REJECT') {
    if (!comment || !comment.trim()) {
      throw AppError.validation([{ field: 'comment', message: 'Comment is required when rejecting a step.' }]);
    }

    currentStep.status = STEP_STATUSES.REJECTED;
    currentStep.actor = actorUser.id;
    currentStep.comment = comment.trim();
    currentStep.actionedAt = new Date();

    request.status = 'REJECTED';

    request.auditLog.push({
      timestamp: new Date(),
      actor: actorUser.id,
      action: 'REJECTED',
      stepIndex: numericStepIndex,
      previousStatus,
      newStatus: 'REJECTED',
      comment: comment.trim(),
    });

    await request.save();

    await createNotification({
      recipientId: request.student,
      requestId: request._id,
      title: 'Request Rejected',
      message: `Your request for ${request.service.name} was rejected at step "${currentStep.name}". Reason: ${comment.trim()}`,
      type: 'STEP_REJECTED',
    });

    return getRequestById(request._id.toString(), actorUser);
  }

  // APPROVE branch
  currentStep.status = STEP_STATUSES.APPROVED;
  currentStep.actor = actorUser.id;
  currentStep.comment = comment ? comment.trim() : null;
  currentStep.actionedAt = new Date();

  const nextStepIndex = numericStepIndex + 1;
  const isLastStep = nextStepIndex >= request.runtimeSteps.length;

  let newStatus;

  if (isLastStep) {
    // Determine terminal completion status
    if (request.service.slug === 'equipment-booking') {
      newStatus = 'BOOKING_CONFIRMED';
    } else {
      newStatus = 'COMPLETED';
    }
  } else {
    // Advance to next step
    request.currentStepIndex = nextStepIndex;
    const workflow = await Workflow.findById(request.workflow);
    const nextDef = workflow?.steps?.find((s) => s.stepIndex === nextStepIndex);
    newStatus = nextDef?.pendingStatus || 'DEPARTMENT_VERIFICATION_PENDING';
  }

  request.status = newStatus;

  request.auditLog.push({
    timestamp: new Date(),
    actor: actorUser.id,
    action: 'APPROVED',
    stepIndex: numericStepIndex,
    previousStatus,
    newStatus,
    comment: comment ? comment.trim() : null,
  });

  await request.save();

  // Notifications
  const isComplete = newStatus === 'COMPLETED' || newStatus === 'BOOKING_CONFIRMED';
  await createNotification({
    recipientId: request.student,
    requestId: request._id,
    title: isComplete ? 'Request Completed' : 'Step Approved',
    message: isComplete
      ? `Your request for ${request.service.name} has been completed!`
      : `Step "${currentStep.name}" for your request has been approved. Status is now ${newStatus}.`,
    type: isComplete ? 'REQUEST_COMPLETED' : 'STEP_APPROVED',
  });

  // If next step is payment, notify student specifically
  if (!isLastStep && request.runtimeSteps[nextStepIndex]?.isPaymentStep) {
    await createNotification({
      recipientId: request.student,
      requestId: request._id,
      title: 'Payment Required',
      message: `Your ID Card Replacement request is ready for payment. Please proceed to simulate payment.`,
      type: 'PAYMENT_REQUIRED',
    });
  }

  return getRequestById(request._id.toString(), actorUser);
}

/**
 * Confirm simulated payment for ID Card Replacement workflow.
 */
export async function confirmPayment({ requestId, studentUser }) {
  const request = await Request.findById(requestId).populate('service');
  if (!request) {
    throw AppError.notFound(`Request not found: ${requestId}`);
  }

  // Access rule: Only the requesting student can pay
  if (request.student.toString() !== studentUser.id) {
    throw AppError.forbidden('Only the student who submitted this request can confirm payment.');
  }

  if (request.status !== 'PAYMENT_REQUIRED') {
    throw AppError.badRequest(
      `Cannot confirm payment. Request is in "${request.status}" status, but expected "PAYMENT_REQUIRED".`,
      'INVALID_TRANSITION'
    );
  }

  const currentStep = request.runtimeSteps[request.currentStepIndex];
  if (!currentStep || !currentStep.isPaymentStep) {
    throw AppError.badRequest('Current step is not a payment step.', 'INVALID_TRANSITION');
  }

  currentStep.status = STEP_STATUSES.PAYMENT_COMPLETED;
  currentStep.actor = studentUser.id;
  currentStep.comment = 'Simulated fee payment confirmed by student.';
  currentStep.actionedAt = new Date();

  const previousStatus = request.status;
  const nextStepIndex = request.currentStepIndex + 1;
  const workflow = await Workflow.findById(request.workflow);
  const nextDef = workflow?.steps?.find((s) => s.stepIndex === nextStepIndex);

  const newStatus = nextDef?.pendingStatus || 'ADMIN_APPROVAL_PENDING';
  request.currentStepIndex = nextStepIndex;
  request.status = newStatus;

  request.auditLog.push({
    timestamp: new Date(),
    actor: studentUser.id,
    action: 'PAYMENT_COMPLETED',
    stepIndex: request.currentStepIndex - 1,
    previousStatus,
    newStatus,
    comment: 'Fee payment confirmed.',
  });

  await request.save();

  await createNotification({
    recipientId: studentUser.id,
    requestId: request._id,
    title: 'Payment Confirmed',
    message: `Payment confirmed for request ${request.requestNumber}. Request sent for final administrative approval.`,
    type: 'INFO',
  });

  return getRequestById(request._id.toString(), studentUser);
}

/**
 * Get staff pending review queue.
 */
export async function getStaffQueue(user, { page = 1, limit = 50 } = {}) {
  const activeStatuses = REQUEST_STATUSES.filter((s) => !isTerminalStatus(s) && s !== 'PAYMENT_REQUIRED');

  const query = {
    status: { $in: activeStatuses },
  };

  // Staff sees steps assigned to 'staff'
  if (user.role === 'staff') {
    query['runtimeSteps.assignedRole'] = 'staff';
  }

  const requests = await Request.find(query)
    .populate('student', 'name email studentId')
    .populate('service', 'name slug category')
    .sort({ createdAt: 1 })
    .lean();

  const now = new Date();

  // Filter to items where current step matches staff role/queue
  const queueItems = [];
  for (const req of requests) {
    const currentStep = req.runtimeSteps?.[req.currentStepIndex];
    if (!currentStep) continue;

    if (user.role === 'staff' && currentStep.assignedRole !== 'staff') {
      continue;
    }

    const waitingHours = Math.max(0, Math.round((now - new Date(req.createdAt)) / (1000 * 60 * 60)));

    queueItems.push({
      stepId: `${req._id}-${req.currentStepIndex}`,
      requestId: req._id.toString(),
      requestNumber: req.requestNumber,
      serviceName: req.service?.name || 'Unknown Service',
      serviceCategory: req.service?.category,
      studentName: req.student?.name || 'Unknown Student',
      studentEmail: req.student?.email,
      studentIdNumber: req.student?.studentId,
      stepIndex: req.currentStepIndex,
      stepName: currentStep.name,
      assignedRole: currentStep.assignedRole,
      status: req.status,
      submittedAt: req.createdAt,
      waitingHours,
    });
  }

  return queueItems;
}

/**
 * Admin dashboard statistics.
 */
export async function getAdminStats(institutionId = null) {
  const match = {};
  if (institutionId) {
    match.institution = new mongoose.Types.ObjectId(institutionId);
  }

  const [totalRequests, completedRequests, rejectedRequests, pendingRequests, equipmentStats, byServiceRaw] =
    await Promise.all([
      Request.countDocuments(match),
      Request.countDocuments({ ...match, status: { $in: ['COMPLETED', 'BOOKING_CONFIRMED'] } }),
      Request.countDocuments({ ...match, status: 'REJECTED' }),
      Request.countDocuments({ ...match, status: { $nin: ['COMPLETED', 'BOOKING_CONFIRMED', 'REJECTED'] } }),
      // Equipment bookings
      Request.aggregate([
        {
          $lookup: {
            from: 'services',
            localField: 'service',
            foreignField: '_id',
            as: 'serviceDoc',
          },
        },
        { $unwind: '$serviceDoc' },
        { $match: { 'serviceDoc.slug': 'equipment-booking' } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            confirmed: { $sum: { $cond: [{ $eq: ['$status', 'BOOKING_CONFIRMED'] }, 1, 0] } },
            rejected: { $sum: { $cond: [{ $eq: ['$status', 'REJECTED'] }, 1, 0] } },
            pending: {
              $sum: {
                $cond: [{ $not: [{ $in: ['$status', ['BOOKING_CONFIRMED', 'REJECTED']] }] }, 1, 0],
              },
            },
          },
        },
      ]),
      // Requests by service
      Request.aggregate([
        {
          $lookup: {
            from: 'services',
            localField: 'service',
            foreignField: '_id',
            as: 'serviceDoc',
          },
        },
        { $unwind: '$serviceDoc' },
        {
          $group: {
            _id: '$serviceDoc.name',
            total: { $sum: 1 },
            pending: {
              $sum: {
                $cond: [{ $not: [{ $in: ['$status', ['COMPLETED', 'BOOKING_CONFIRMED', 'REJECTED']] }] }, 1, 0],
              },
            },
          },
        },
        { $sort: { total: -1 } },
      ]),
    ]);

  const eq = equipmentStats[0] || { total: 0, confirmed: 0, rejected: 0, pending: 0 };

  return {
    requests: {
      total: totalRequests,
      pending: pendingRequests,
      completed: completedRequests,
      rejected: rejectedRequests,
    },
    bookings: {
      total: eq.total,
      pending: eq.pending,
      confirmed: eq.confirmed,
      rejected: eq.rejected,
    },
    byService: byServiceRaw.map((b) => ({
      serviceName: b._id,
      total: b.total,
      pending: b.pending,
    })),
  };
}
