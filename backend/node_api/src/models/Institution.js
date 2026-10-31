/**
 * src/models/Institution.js
 *
 * Represents a university or college using UniFlow.
 *
 * Phase 1 note: The MVP operates with a single institution (UniFlow Demo University)
 * populated by the seed script. Multi-institution support is future scope.
 */

import mongoose, { Schema } from 'mongoose';

const institutionSchema = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Institution name is required.'],
      trim: true,
      minlength: [2, 'Institution name must be at least 2 characters.'],
      maxlength: [200, 'Institution name cannot exceed 200 characters.'],
    },

    // URL-safe unique identifier — e.g. "uniflow-demo-university"
    slug: {
      type: String,
      required: [true, 'Institution slug is required.'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[a-z0-9-]+$/, 'Slug may only contain lowercase letters, numbers and hyphens.'],
    },

    // Short institutional code — e.g. "UDU"
    code: {
      type: String,
      required: [true, 'Institution code is required.'],
      unique: true,
      uppercase: true,
      trim: true,
      maxlength: [20, 'Institution code cannot exceed 20 characters.'],
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    collection: 'institutions',
  }
);

// Note: slug and code unique indexes are declared via `unique: true` in the field
// definitions above. Mongoose creates those indexes automatically — no need to
// repeat them here.

export default mongoose.model('Institution', institutionSchema);
