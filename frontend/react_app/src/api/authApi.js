/**
 * src/api/authApi.js
 *
 * Authentication and identity API calls.
 */

import httpClient from './httpClient.js';

export async function loginUser({ email, password }) {
  const response = await httpClient.post('/auth/login', { email, password });
  return response.data.data; // { token, user }
}

export async function registerStudent({ name, email, password, studentId = '' }) {
  const payload = {
    name,
    email,
    password,
    role: 'student', // Security rule: public registration is locked to student
  };

  if (studentId && studentId.trim()) {
    payload.studentId = studentId.trim();
  }

  const response = await httpClient.post('/auth/register', payload);
  return response.data.data; // { token, user }
}

export async function getCurrentUser() {
  const response = await httpClient.get('/auth/me');
  return response.data.data.user;
}

export async function getDepartments() {
  const response = await httpClient.get('/departments');
  return response.data.data; // array of departments
}
