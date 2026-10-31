/**
 * src/api/servicesApi.js
 *
 * Campus Services Catalogue API client.
 */

import httpClient from './httpClient.js';

/**
 * List all active campus services.
 * @param {Object} [params] - Query params: category, institutionId
 * @returns {Promise<Array>} List of services
 */
export async function getServices(params = {}) {
  const response = await httpClient.get('/services', { params });
  return response.data.data;
}

/**
 * Get detailed information about a single service by ID or slug.
 * @param {string} idOrSlug - Service ObjectId or slug string
 * @returns {Promise<Object>} Service details including workflow steps and form fields
 */
export async function getServiceById(idOrSlug) {
  const response = await httpClient.get(`/services/${idOrSlug}`);
  return response.data.data;
}
