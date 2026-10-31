/**
 * src/models/Department.js
 *
 * Represents a department within an institution.
 * Departments are assigned to workflow steps so that the correct staff
 * queue receives pending requests.
 */

import mongoose, { Schema } from 'mongoose';

const departmentSchema = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Department name is required.'],
      trim: true,
      minlength: [2, 'Department name must be at least 2 characters.'],
      maxlength: [150, 'Department name cannot exceed 150 characters.'],
    },

    // Short code used in logging and UI — e.g. "CS", "SEC", "ADMIN"
    code: {
      type: String,
      required: [true, 'Department code is required.'],
      uppercase: true,
      trim: true,
      maxlength: [20, 'Department code cannot exceed 20 characters.'],
    },

    institution: {
      type: Schema.Types.ObjectId,
      ref: 'Institution',
      required: [true, 'Department must belong to an institution.'],
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    collection: 'departments',
  }
);

// Department code must be unique within an institution
departmentSchema.index({ institution: 1, code: 1 }, { unique: true });

export default mongoose.model('Department', departmentSchema);
