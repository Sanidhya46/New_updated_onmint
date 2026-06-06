{
  "info": {
    "_postman_id": "830d2a9d-43a4-41cc-9101-76825942bba9",
    "name": "Healthcare Management System - Admin API",
    "description": "Complete Admin API collection for Healthcare Management System including user management, provider approvals, medicine management, ambulance management, blood bank management, pathology management, and analytics",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    "_exporter_id": "37469907"
  },
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Admin Login",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "if (pm.response.code === 200) {",
                  "    const response = pm.response.json();",
                  "    pm.collectionVariables.set('ADMIN_TOKEN', response.data.accessToken);",
                  "    pm.collectionVariables.set('USER_ID', response.data.user._id);",
                  "    console.log('Admin token set successfully');",
                  "}"
                ],
                "type": "text/javascript",
                "packages": {},
                "requests": {}
              }
            }
          ],
          "request": {
            "auth": {
              "type": "noauth"
            },
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"admin123@example.com\",\n  \"password\": \"SecurePass@123!\",\n  \"phone\": \"9876543825\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/auth/login",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "auth",
                "login"
              ]
            },
            "description": "Login as admin user. The access token will be automatically saved to ADMIN_TOKEN variable."
          },
          "response": []
        },
        {
          "name": "Get Admin Profile",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/auth/me",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "auth",
                "me"
              ]
            },
            "description": "Get current admin user profile"
          },
          "response": []
        }
      ],
      "description": "Admin authentication endpoints"
    },
    {
      "name": "Dashboard & Analytics",
      "item": [
        {
          "name": "Get Dashboard",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/dashboard",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "dashboard"
              ]
            },
            "description": "Get admin dashboard with overview statistics including total users, bookings, revenue, and pending approvals"
          },
          "response": []
        },
        {
          "name": "Get Service Statistics",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/stats/services",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "stats",
                "services"
              ]
            },
            "description": "Get statistics for all services (doctors, nurses, ambulances, pharmacies, blood banks, pathology labs)"
          },
          "response": []
        }
      ],
      "description": "Admin dashboard and analytics endpoints"
    },
    {
      "name": "Provider Approvals",
      "item": [
        {
          "name": "Get Pending Approvals",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/approvals/pending",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "approvals",
                "pending"
              ]
            },
            "description": "Get list of all providers pending approval (doctors, nurses, pharmacists, ambulances, blood banks, pathology labs)"
          },
          "response": []
        },
        {
          "name": "Approve Provider",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "if (pm.response.code === 200) {",
                  "    console.log('Provider approved successfully');",
                  "}"
                ],
                "type": "text/javascript"
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"notes\": \"All credentials verified. Approved for service.\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/providers/:id/approve",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "providers",
                ":id",
                "approve"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{PROVIDER_ID}}",
                  "description": "Provider ID to approve"
                }
              ]
            },
            "description": "Approve a provider (doctor, nurse, pharmacist, ambulance, blood bank, pathology lab). Provider status will be changed to 'approved'."
          },
          "response": []
        },
        {
          "name": "Reject Provider",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"reason\": \"Invalid license credentials. Please resubmit with valid documents.\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/providers/:id/reject",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "providers",
                ":id",
                "reject"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{PROVIDER_ID}}",
                  "description": "Provider ID to reject"
                }
              ]
            },
            "description": "Reject a provider application with reason. Provider status will be changed to 'rejected'."
          },
          "response": []
        }
      ],
      "description": "Manage provider approval requests"
    },
    {
      "name": "User Management",
      "item": [
        {
          "name": "Get All Users",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/users?page=1&limit=20&role=all&status=all",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "users"
              ],
              "query": [
                {
                  "key": "page",
                  "value": "1",
                  "description": "Page number"
                },
                {
                  "key": "limit",
                  "value": "20",
                  "description": "Items per page"
                },
                {
                  "key": "role",
                  "value": "all",
                  "description": "Filter by role: all, patient, doctor, nurse, pharmacist, ambulance, bloodbank, pathology"
                },
                {
                  "key": "status",
                  "value": "all",
                  "description": "Filter by status: all, pending, approved, rejected, blocked, active"
                }
              ]
            },
            "description": "Get paginated list of all users with optional filters for role and status"
          },
          "response": []
        },
        {
          "name": "Block User",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"reason\": \"Violation of terms of service. Multiple complaints received.\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/users/:id/block",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "users",
                ":id",
                "block"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{USER_ID}}",
                  "description": "User ID to block"
                }
              ]
            },
            "description": "Block a user account. User will not be able to login or access services."
          },
          "response": []
        },
        {
          "name": "Unblock User",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"notes\": \"Issue resolved. Account restored.\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/users/:id/unblock",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "users",
                ":id",
                "unblock"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{USER_ID}}",
                  "description": "User ID to unblock"
                }
              ]
            },
            "description": "Unblock a previously blocked user account. User will be able to login and access services again."
          },
          "response": []
        }
      ],
      "description": "Manage all users in the system"
    },
    {
      "name": "Medicine Management",
      "item": [
        {
          "name": "Get All Medicines",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/medicines?page=1&limit=20&search=&category=",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "medicines"
              ],
              "query": [
                {
                  "key": "page",
                  "value": "1",
                  "description": "Page number"
                },
                {
                  "key": "limit",
                  "value": "20",
                  "description": "Items per page"
                },
                {
                  "key": "search",
                  "value": "",
                  "description": "Search by medicine name or generic name"
                },
                {
                  "key": "category",
                  "value": "",
                  "description": "Filter by category"
                }
              ]
            },
            "description": "Get paginated list of all medicines with optional search and category filters"
          },
          "response": []
        },
        {
          "name": "Create Medicine",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "if (pm.response.code === 201) {",
                  "    const response = pm.response.json();",
                  "    pm.collectionVariables.set('MEDICINE_ID', response.data._id);",
                  "    console.log('Medicine created with ID:', response.data._id);",
                  "}"
                ],
                "type": "text/javascript"
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"name\": \"Paracetamol\",\n  \"genericName\": \"Acetaminophen\",\n  \"manufacturer\": \"Cipla Ltd\",\n  \"description\": \"Pain reliever and fever reducer\",\n  \"price\": 50,\n  \"discountedPrice\": 45,\n  \"stock\": 1000,\n  \"category\": \"Analgesics\",\n  \"requiresPrescription\": false,\n  \"dosageForm\": \"Tablet\",\n  \"strength\": \"500mg\",\n  \"packaging\": \"Strip of 10 tablets\",\n  \"expiryDate\": \"2025-12-31\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/medicines",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "medicines"
              ]
            },
            "description": "Create a new medicine in the system. Medicine ID will be saved to MEDICINE_ID variable."
          },
          "response": []
        },
        {
          "name": "Update Medicine",
          "request": {
            "method": "PUT",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"price\": 55,\n  \"discountedPrice\": 50,\n  \"stock\": 1500,\n  \"description\": \"Pain reliever and fever reducer - Updated formula\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/medicines/:id",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "medicines",
                ":id"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{MEDICINE_ID}}",
                  "description": "Medicine ID to update"
                }
              ]
            },
            "description": "Update medicine details including price, stock, description, etc."
          },
          "response": []
        },
        {
          "name": "Delete Medicine",
          "request": {
            "method": "DELETE",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/medicines/:id",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "medicines",
                ":id"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{MEDICINE_ID}}",
                  "description": "Medicine ID to delete"
                }
              ]
            },
            "description": "Delete a medicine from the system. This action cannot be undone."
          },
          "response": []
        }
      ],
      "description": "Manage medicine inventory for pharmacies"
    },
    {
      "name": "Ambulance Management",
      "item": [
        {
          "name": "Get All Ambulances",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/ambulances?page=1&limit=20",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "ambulances"
              ],
              "query": [
                {
                  "key": "page",
                  "value": "1",
                  "description": "Page number"
                },
                {
                  "key": "limit",
                  "value": "20",
                  "description": "Items per page"
                }
              ]
            },
            "description": "Get paginated list of all ambulances in the system"
          },
          "response": []
        },
        {
          "name": "Create Ambulance",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "if (pm.response.code === 201) {",
                  "    const response = pm.response.json();",
                  "    pm.collectionVariables.set('AMBULANCE_ID', response.data._id);",
                  "    console.log('Ambulance created with ID:', response.data._id);",
                  "}"
                ],
                "type": "text/javascript"
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"driverName\": \"Rajesh Kumar\",\n  \"driverLicense\": \"MH-DL-123456789\",\n  \"vehicleNumber\": \"MH-01-AB-1234\",\n  \"vehicleType\": \"Advanced Life Support\",\n  \"equipmentAvailable\": [\n    \"Oxygen Cylinder\",\n    \"Defibrillator\",\n    \"Stretcher\",\n    \"First Aid Kit\",\n    \"Ventilator\"\n  ],\n  \"isAvailable\": true,\n  \"currentLocation\": {\n    \"type\": \"Point\",\n    \"coordinates\": [72.8777, 19.0760]\n  }\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/ambulances",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "ambulances"
              ]
            },
            "description": "Create a new ambulance in the system. Ambulance ID will be saved to AMBULANCE_ID variable."
          },
          "response": []
        },
        {
          "name": "Update Ambulance",
          "request": {
            "method": "PUT",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"driverName\": \"Rajesh Kumar Singh\",\n  \"isAvailable\": false,\n  \"equipmentAvailable\": [\n    \"Oxygen Cylinder\",\n    \"Defibrillator\",\n    \"Stretcher\",\n    \"First Aid Kit\",\n    \"Ventilator\",\n    \"ECG Monitor\"\n  ]\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/ambulances/:id",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "ambulances",
                ":id"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{AMBULANCE_ID}}",
                  "description": "Ambulance ID to update"
                }
              ]
            },
            "description": "Update ambulance details including driver info, availability, equipment, etc."
          },
          "response": []
        },
        {
          "name": "Delete Ambulance",
          "request": {
            "method": "DELETE",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/ambulances/:id",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "ambulances",
                ":id"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{AMBULANCE_ID}}",
                  "description": "Ambulance ID to delete"
                }
              ]
            },
            "description": "Delete an ambulance from the system. This action cannot be undone."
          },
          "response": []
        }
      ],
      "description": "Manage ambulance fleet"
    },
    {
      "name": "Blood Bank Management",
      "item": [
        {
          "name": "Get All Blood Banks",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/bloodbanks?page=1&limit=20",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "bloodbanks"
              ],
              "query": [
                {
                  "key": "page",
                  "value": "1",
                  "description": "Page number"
                },
                {
                  "key": "limit",
                  "value": "20",
                  "description": "Items per page"
                }
              ]
            },
            "description": "Get paginated list of all blood banks with their current stock levels"
          },
          "response": []
        },
        {
          "name": "Update Blood Stock",
          "request": {
            "method": "PUT",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"bloodStock\": [\n    {\n      \"bloodGroup\": \"A+\",\n      \"unitsAvailable\": 50\n    },\n    {\n      \"bloodGroup\": \"A-\",\n      \"unitsAvailable\": 20\n    },\n    {\n      \"bloodGroup\": \"B+\",\n      \"unitsAvailable\": 45\n    },\n    {\n      \"bloodGroup\": \"B-\",\n      \"unitsAvailable\": 15\n    },\n    {\n      \"bloodGroup\": \"AB+\",\n      \"unitsAvailable\": 30\n    },\n    {\n      \"bloodGroup\": \"AB-\",\n      \"unitsAvailable\": 10\n    },\n    {\n      \"bloodGroup\": \"O+\",\n      \"unitsAvailable\": 60\n    },\n    {\n      \"bloodGroup\": \"O-\",\n      \"unitsAvailable\": 25\n    }\n  ]\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/bloodbanks/:id/stock",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "bloodbanks",
                ":id",
                "stock"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{BLOODBANK_ID}}",
                  "description": "Blood Bank ID"
                }
              ]
            },
            "description": "Update blood stock levels for a blood bank. Provide units available for each blood group."
          },
          "response": []
        }
      ],
      "description": "Manage blood bank inventory"
    },
    {
      "name": "Pathology Lab Management",
      "item": [
        {
          "name": "Get All Pathology Labs",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{BASE_URL}}/admin/pathology?page=1&limit=20",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "pathology"
              ],
              "query": [
                {
                  "key": "page",
                  "value": "1",
                  "description": "Page number"
                },
                {
                  "key": "limit",
                  "value": "20",
                  "description": "Items per page"
                }
              ]
            },
            "description": "Get paginated list of all pathology labs with their available tests"
          },
          "response": []
        },
        {
          "name": "Update Pathology Tests",
          "request": {
            "method": "PUT",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"testsOffered\": [\n    {\n      \"name\": \"Complete Blood Count (CBC)\",\n      \"description\": \"Measures different components of blood\",\n      \"price\": 300,\n      \"preparationInstructions\": \"No fasting required\",\n      \"reportDeliveryTime\": \"24hrs\"\n    },\n    {\n      \"name\": \"Lipid Profile\",\n      \"description\": \"Measures cholesterol and triglycerides\",\n      \"price\": 500,\n      \"preparationInstructions\": \"12 hours fasting required\",\n      \"reportDeliveryTime\": \"24hrs\"\n    },\n    {\n      \"name\": \"Thyroid Function Test (TFT)\",\n      \"description\": \"Measures thyroid hormone levels\",\n      \"price\": 600,\n      \"preparationInstructions\": \"No special preparation needed\",\n      \"reportDeliveryTime\": \"48hrs\"\n    },\n    {\n      \"name\": \"Blood Sugar (Fasting)\",\n      \"description\": \"Measures fasting blood glucose level\",\n      \"price\": 100,\n      \"preparationInstructions\": \"8-10 hours fasting required\",\n      \"reportDeliveryTime\": \"24hrs\"\n    },\n    {\n      \"name\": \"Liver Function Test (LFT)\",\n      \"description\": \"Measures liver enzyme levels\",\n      \"price\": 700,\n      \"preparationInstructions\": \"No fasting required\",\n      \"reportDeliveryTime\": \"24hrs\"\n    }\n  ]\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{BASE_URL}}/admin/pathology/:id/tests",
              "host": [
                "{{BASE_URL}}"
              ],
              "path": [
                "admin",
                "pathology",
                ":id",
                "tests"
              ],
              "variable": [
                {
                  "key": "id",
                  "value": "{{PATHOLOGY_ID}}",
                  "description": "Pathology Lab ID"
                }
              ]
            },
            "description": "Update tests offered by a pathology lab including test details, pricing, and preparation instructions"
          },
          "response": []
        }
      ],
      "description": "Manage pathology lab tests and services"
    }
  ],
  "auth": {
    "type": "bearer",
    "bearer": [
      {
        "key": "token",
        "value": "{{ADMIN_TOKEN}}",
        "type": "string"
      }
    ]
  },
  "variable": [
    {
      "key": "BASE_URL",
      "value": "http://localhost:5000/api/v1",
      "type": "string"
    },
    {
      "key": "ADMIN_TOKEN",
      "value": "",
      "type": "string",
      "description": "Admin access token - set after admin login"
    },
    {
      "key": "USER_ID",
      "value": "",
      "type": "string"
    },
    {
      "key": "PROVIDER_ID",
      "value": "",
      "type": "string"
    },
    {
      "key": "MEDICINE_ID",
      "value": "",
      "type": "string"
    },
    {
      "key": "AMBULANCE_ID",
      "value": "",
      "type": "string"
    },
    {
      "key": "BLOODBANK_ID",
      "value": "",
      "type": "string"
    },
    {
      "key": "PATHOLOGY_ID",
      "value": "",
      "type": "string"
    }
  ]
}