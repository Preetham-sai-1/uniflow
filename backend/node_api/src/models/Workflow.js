/**
 * src/models/Workflow.js
 *
 * A Workflow definition is a TEMPLATE — it describes the ordered sequence
 * of approval steps for a service. It is not a live instance.
 *
 * The runtime state of an individual student request is tracked in Request.js.
 *
 * Each step definition includes:
 *  - stepIndex      : 0-based ordering position
 *  - name           : human-readable step name
 *  - assignedRole   : which role must action this step (student | staff | admin)
 *  - department     : optional — narrows the staff queue to a specific department
 *  - isPaymentStep  : true for the simulated payment step (ID Card workflow)
 *  - pendingStatus  : the Request.status value set when this step becomes active
 *  - requiresComment: if true, comment is mandatory when approving or rejecting
 */

import mongoose, { Schema } from 'mongoose';

// ─── Step definition sub-schema ───────────────────────────────────────────────

const stepDefinitionSchema = new Schema(
  {
    stepIndex: {
      type: Number,
      required: [true, 'Step index is required.'],
      min: [0, 'Step index must be 0 or greater.'],
    },

    name: {
      type: String,
      required: [true, 'Step name is required.'],
      trim: true,
    },

    description: {
      type: String,
      trim: true,
      default: '',
    },

    // The role whose queue this step appears in
    assignedRole: {
      type: String,
      required: [true, 'Assigned role is required.'],
      enum: {
        values: ['student', 'staff', 'admin'],
        message: 'Assigned role must be student, staff, or admin.',
      },
    },

    // Optional: restrict the step to staff in a particular department
    department: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
    },

    // True for the payment confirmation step (student-actioned, not staff)
    isPaymentStep: {
      type: Boolean,
      default: false,
    },

    // The overall Request.status value while this step is pending
    // e.g. "DEPARTMENT_VERIFICATION_PENDING", "SECURITY_REVIEW_PENDING"
    pendingStatus: {
      type: String,
      required: [true, 'Pending status is required for each step.'],
      trim: true,
    },

    // If true, the comment field is mandatory when a staff/admin actions this step
    requiresComment: {
      type: Boolean,
      default: false,
    },
  },
  { _id: false }
);

// ─── Workflow schema ───────────────────────────────────────────────────────────

const workflowSchema = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Workflow name is required.'],
      trim: true,
      maxlength: [200, 'Workflow name cannot exceed 200 characters.'],
    },

    // Back-reference to the service this workflow governs
    service: {
      type: Schema.Types.ObjectId,
      ref: 'Service',
      required: [true, 'Workflow must be associated with a service.'],
    },

    institution: {
      type: Schema.Types.ObjectId,
      ref: 'Institution',
      required: [true, 'Workflow must belong to an institution.'],
    },

    // Increment when the step structure changes so historical requests
    // can reference the exact definition that was active when they were submitted.
    version: {
      type: Number,
      required: true,
      default: 1,
      min: [1, 'Version must be at least 1.'],
    },

    steps: {
      type: [stepDefinitionSchema],
      required: [true, 'Workflow must have at least one step.'],
      validate: {
        validator: (v) => Array.isArray(v) && v.length > 0,
        message: 'Workflow must contain at least one step.',
      },
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    collection: 'workflows',
  }
);

workflowSchema.index({ institution: 1, isActive: 1 });

export default mongoose.model('Workflow', workflowSchema);
