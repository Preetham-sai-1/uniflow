/**
 * src/models/Service.js
 *
 * A campus service offering visible to students in the service catalogue.
 * Each active Service is linked to a Workflow definition that describes
 * its approval steps.
 *
 * formFields defines what the student submission form looks like.
 * The runtime submitted values are stored in Request.formData (free-form object).
 */

import mongoose, { Schema } from 'mongoose';

// ─── Form field definition sub-schema ────────────────────────────────────────
// Describes one input on the student submission form (not runtime data)

const formFieldSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    label: { type: String, required: true, trim: true },
    type: {
      type: String,
      required: true,
      enum: ['text', 'textarea', 'number', 'select', 'date', 'datetime', 'checkbox'],
    },
    options: { type: [String], default: [] }, // for 'select' type
    required: { type: Boolean, default: true },
    placeholder: { type: String, trim: true, default: '' },
  },
  { _id: false }
);

// ─── Service schema ───────────────────────────────────────────────────────────

const serviceSchema = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Service name is required.'],
      trim: true,
      maxlength: [150, 'Service name cannot exceed 150 characters.'],
    },

    // URL-safe unique identifier — e.g. "bonafide-certificate"
    slug: {
      type: String,
      required: [true, 'Service slug is required.'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[a-z0-9-]+$/, 'Slug may only contain lowercase letters, numbers and hyphens.'],
    },

    description: {
      type: String,
      required: [true, 'Service description is required.'],
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters.'],
    },

    category: {
      type: String,
      required: [true, 'Service category is required.'],
      trim: true,
      enum: {
        values: ['Academic', 'Identity', 'Resources', 'Finance', 'Other'],
        message: 'Category must be one of: Academic, Identity, Resources, Finance, Other.',
      },
    },

    // Human-readable list of what students should have ready before submitting
    requiredDocuments: {
      type: [String],
      default: [],
    },

    // The department primarily responsible for this service
    responsibleDepartment: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      required: [true, 'Responsible department is required.'],
    },

    institution: {
      type: Schema.Types.ObjectId,
      ref: 'Institution',
      required: [true, 'Service must belong to an institution.'],
    },

    // The workflow definition that governs this service's approval steps
    workflow: {
      type: Schema.Types.ObjectId,
      ref: 'Workflow',
      default: null,
    },

    // Dynamic form definition — rendered by the frontend
    formFields: {
      type: [formFieldSchema],
      default: [],
    },

    estimatedDays: {
      type: Number,
      default: 3,
      min: [1, 'Estimated days must be at least 1.'],
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    collection: 'services',
  }
);

serviceSchema.index({ institution: 1, isActive: 1 });
// Note: slug unique index is created by `unique: true` on the field definition above.

export default mongoose.model('Service', serviceSchema);
