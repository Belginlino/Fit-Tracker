#!/usr/bin/env python3
"""
FitTrack Appwrite Provisioning Script
Automatically creates the FitTrack database, 7 collections, attributes, indexes, and storage bucket in your Appwrite project.
"""

import sys
import json
import time
import urllib.request
import urllib.error

# Ensure immediate unbuffered console logging
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(line_buffering=True)

DEFAULT_ENDPOINT = "https://cloud.appwrite.io/v1"
DEFAULT_DATABASE_ID = "fittrack"
DEFAULT_BUCKET_ID = "progress-photos"

def api_request(url, method="GET", headers=None, data=None):
    if headers is None:
        headers = {}
    req = urllib.request.Request(url, method=method, headers=headers)
    if data is not None:
        req.data = json.dumps(data).encode("utf-8")
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as response:
            body = response.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            err_json = json.loads(body)
        except Exception:
            err_json = {"message": body}
        return {"_error": True, "status": e.code, "error": err_json}
    except Exception as e:
        return {"_error": True, "status": 0, "error": str(e)}

def wait_for_attributes(endpoint, headers, database_id, collection_id):
    """Wait for all collection attributes to finish processing in Appwrite."""
    url = f"{endpoint}/databases/{database_id}/collections/{collection_id}/attributes"
    for _ in range(30):
        res = api_request(url, headers=headers)
        if res.get("_error"):
            time.sleep(1)
            continue
        attrs = res.get("attributes", [])
        if attrs and all(a.get("status") == "available" for a in attrs):
            return True
        time.sleep(1)
    return True

def setup_appwrite(endpoint, project_id, api_key, database_id=DEFAULT_DATABASE_ID, bucket_id=DEFAULT_BUCKET_ID):
    headers = {
        "X-Appwrite-Project": project_id,
        "X-Appwrite-Key": api_key,
    }

    print(f"\n==========================================")
    print(f" Connecting to Appwrite: {endpoint}")
    print(f" Project ID: {project_id}")
    print(f" Database ID: {database_id}")
    print(f" Bucket ID: {bucket_id}")
    print(f"==========================================\n")

    # 1. Create or verify Database
    print(f"[1/4] Checking Database '{database_id}'...")
    db_url = f"{endpoint}/databases/{database_id}"
    db_res = api_request(db_url, headers=headers)
    if db_res.get("_error") and db_res.get("status") == 404:
        print(f"  Creating database '{database_id}'...")
        create_db_res = api_request(
            f"{endpoint}/databases",
            method="POST",
            headers=headers,
            data={"databaseId": database_id, "name": "FitTrack Database"}
        )
        if create_db_res.get("_error"):
            print(f"  Error creating database: {create_db_res['error']}")
            return False
        print("  Database created successfully.")
    elif not db_res.get("_error"):
        print("  Database exists.")
    else:
        print(f"  Error checking database: {db_res['error']}")
        return False

    # 2. Define Collections & Attributes
    collections = {
        "profiles": {
            "name": "Profiles",
            "attributes": [
                {"type": "string", "key": "name", "size": 128, "required": False, "default": "Athlete"},
                {"type": "string", "key": "goal", "size": 64, "required": False, "default": "Build Muscle"},
                {"type": "float", "key": "height", "required": False, "default": 178.0},
                {"type": "float", "key": "current_weight", "required": False, "default": 74.2},
                {"type": "float", "key": "target_weight", "required": False, "default": 78.0},
                {"type": "string", "key": "preferred_reminder_time", "size": 16, "required": False, "default": "18:00:00"},
                {"type": "integer", "key": "workout_streak", "required": False, "default": 0},
                {"type": "integer", "key": "photo_streak", "required": False, "default": 0},
                {"type": "boolean", "key": "has_completed_onboarding", "required": False, "default": False},
            ],
            "indexes": []
        },
        "workouts": {
            "name": "Workouts",
            "attributes": [
                {"type": "string", "key": "user_id", "size": 64, "required": True},
                {"type": "string", "key": "title", "size": 128, "required": True, "default": "Workout Session"},
                {"type": "string", "key": "workout_date", "size": 64, "required": True},
                {"type": "integer", "key": "duration_minutes", "required": False, "default": 45},
                {"type": "string", "key": "notes", "size": 2048, "required": False, "default": ""},
            ],
            "indexes": [
                {"key": "idx_workouts_user_date", "type": "key", "attributes": ["user_id", "workout_date"], "orders": ["ASC", "DESC"]}
            ]
        },
        "workout_exercises": {
            "name": "Workout Exercises",
            "attributes": [
                {"type": "string", "key": "workout_id", "size": 64, "required": True},
                {"type": "string", "key": "user_id", "size": 64, "required": True},
                {"type": "string", "key": "exercise_name", "size": 128, "required": True},
                {"type": "integer", "key": "exercise_order", "required": False, "default": 0},
            ],
            "indexes": [
                {"key": "idx_exercises_workout", "type": "key", "attributes": ["workout_id", "exercise_order"], "orders": ["ASC", "ASC"]}
            ]
        },
        "workout_sets": {
            "name": "Workout Sets",
            "attributes": [
                {"type": "string", "key": "workout_id", "size": 64, "required": True},
                {"type": "string", "key": "workout_exercise_id", "size": 64, "required": True},
                {"type": "string", "key": "user_id", "size": 64, "required": True},
                {"type": "integer", "key": "set_number", "required": True},
                {"type": "float", "key": "weight", "required": False, "default": 0.0},
                {"type": "integer", "key": "reps", "required": False, "default": 0},
                {"type": "boolean", "key": "is_completed", "required": False, "default": True},
            ],
            "indexes": [
                {"key": "idx_sets_exercise", "type": "key", "attributes": ["workout_exercise_id", "set_number"], "orders": ["ASC", "ASC"]}
            ]
        },
        "personal_records": {
            "name": "Personal Records",
            "attributes": [
                {"type": "string", "key": "user_id", "size": 64, "required": True},
                {"type": "string", "key": "exercise_name", "size": 128, "required": True},
                {"type": "float", "key": "max_weight", "required": True},
                {"type": "integer", "key": "max_reps", "required": False, "default": 0},
                {"type": "string", "key": "achieved_at", "size": 64, "required": False, "default": ""},
                {"type": "string", "key": "workout_id", "size": 64, "required": False, "default": ""},
            ],
            "indexes": [
                {"key": "idx_pr_user_exercise", "type": "key", "attributes": ["user_id", "exercise_name"], "orders": ["ASC", "ASC"]}
            ]
        },
        "measurements": {
            "name": "Body Measurements",
            "attributes": [
                {"type": "string", "key": "user_id", "size": 64, "required": True},
                {"type": "string", "key": "measurement_type", "size": 64, "required": True},
                {"type": "float", "key": "value", "required": True},
                {"type": "string", "key": "unit", "size": 16, "required": False, "default": "kg"},
                {"type": "string", "key": "recorded_at", "size": 64, "required": True},
                {"type": "string", "key": "notes", "size": 1024, "required": False, "default": ""},
            ],
            "indexes": [
                {"key": "idx_measurements_user_type_date", "type": "key", "attributes": ["user_id", "measurement_type"], "orders": ["ASC", "ASC"]}
            ]
        },
        "progress_photos": {
            "name": "Progress Photos",
            "attributes": [
                {"type": "string", "key": "user_id", "size": 64, "required": True},
                {"type": "string", "key": "file_id", "size": 64, "required": True},
                {"type": "string", "key": "storage_path", "size": 128, "required": False, "default": ""},
                {"type": "string", "key": "pose", "size": 64, "required": False, "default": "Front"},
                {"type": "string", "key": "workout_id", "size": 64, "required": False, "default": ""},
                {"type": "float", "key": "weight_at_capture", "required": False, "default": 0.0},
                {"type": "string", "key": "notes", "size": 2048, "required": False, "default": ""},
                {"type": "string", "key": "created_at", "size": 64, "required": True},
            ],
            "indexes": [
                {"key": "idx_photos_user_date", "type": "key", "attributes": ["user_id", "created_at"], "orders": ["ASC", "DESC"]}
            ]
        }
    }

    # 3. Create Collections & Attributes
    print(f"\n[2/4] Setting up {len(collections)} Collections...")
    for col_id, col_info in collections.items():
        print(f"  Checking collection '{col_id}' ({col_info['name']})...")
        c_url = f"{endpoint}/databases/{database_id}/collections/{col_id}"
        c_res = api_request(c_url, headers=headers)

        if c_res.get("_error") and c_res.get("status") == 404:
            print(f"    Creating collection '{col_id}'...")
            create_c_res = api_request(
                f"{endpoint}/databases/{database_id}/collections",
                method="POST",
                headers=headers,
                data={
                    "collectionId": col_id,
                    "name": col_info["name"],
                    "permissions": [
                        'read("users")',
                        'create("users")',
                        'update("users")',
                        'delete("users")'
                    ],
                    "documentSecurity": True
                }
            )
            if create_c_res.get("_error"):
                print(f"    Error creating collection: {create_c_res['error']}")
                continue
        elif c_res.get("_error"):
            print(f"    Error checking collection: {c_res['error']}")
            continue

        # Create attributes
        for attr in col_info["attributes"]:
            attr_type = attr["type"]
            attr_key = attr["key"]
            attr_url = f"{endpoint}/databases/{database_id}/collections/{col_id}/attributes/{attr_type}"
            payload = {
                "key": attr_key,
                "required": attr.get("required", False),
            }
            if "size" in attr:
                payload["size"] = attr["size"]
            if not attr.get("required") and "default" in attr:
                payload["default"] = attr["default"]

            attr_res = api_request(attr_url, method="POST", headers=headers, data=payload)
            if attr_res.get("_error"):
                if attr_res.get("status") == 409:
                    pass  # Attribute already exists
                else:
                    print(f"      Attr '{attr_key}' notice: {attr_res['error'].get('message', attr_res['error'])}")
            else:
                print(f"      + Created attribute '{attr_key}' ({attr_type})")

    # Wait for attributes to become available before adding indexes
    print(f"\n[3/4] Creating Indexes...")
    for col_id, col_info in collections.items():
        if not col_info.get("indexes"):
            continue
        wait_for_attributes(endpoint, headers, database_id, col_id)
        for idx in col_info["indexes"]:
            idx_url = f"{endpoint}/databases/{database_id}/collections/{col_id}/indexes"
            idx_res = api_request(idx_url, method="POST", headers=headers, data=idx)
            if idx_res.get("_error"):
                if idx_res.get("status") == 409:
                    pass  # Index already exists
                else:
                    print(f"    Index '{idx['key']}' notice: {idx_res['error'].get('message', idx_res['error'])}")
            else:
                print(f"    + Created index '{idx['key']}' in '{col_id}'")

    # 4. Create Storage Bucket
    print(f"\n[4/4] Checking Storage Bucket '{bucket_id}'...")
    b_url = f"{endpoint}/storage/buckets/{bucket_id}"
    b_res = api_request(b_url, headers=headers)
    if b_res.get("_error") and b_res.get("status") == 404:
        print(f"  Creating bucket '{bucket_id}'...")
        create_b_res = api_request(
            f"{endpoint}/storage/buckets",
            method="POST",
            headers=headers,
            data={
                "bucketId": bucket_id,
                "name": "Progress Photos",
                "permissions": [
                    'read("users")',
                    'create("users")',
                    'update("users")',
                    'delete("users")'
                ],
                "fileSecurity": True,
                "enabled": True,
                "maximumFileSize": 15728640,
                "allowedFileExtensions": ["jpg", "jpeg", "png", "webp"],
                "compression": "none",
                "encryption": True,
                "antivirus": True
            }
        )
        if create_b_res.get("_error"):
            print(f"  Error creating bucket: {create_b_res['error']}")
        else:
            print("  Storage bucket created successfully.")
    elif not b_res.get("_error"):
        print("  Storage bucket exists.")
    else:
        print(f"  Error checking bucket: {b_res['error']}")

    print("\n==========================================")
    print(" [SUCCESS] Appwrite FitTrack Setup Complete!")
    print("==========================================\n")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("\nUsage:")
        print("  python scripts/setup_appwrite.py <PROJECT_ID> <API_KEY> [ENDPOINT]\n")
        print("Example:")
        print("  python scripts/setup_appwrite.py 65a1b2c3d4e5f6 key_abc123... https://cloud.appwrite.io/v1\n")
        sys.exit(1)

    project_id = sys.argv[1]
    api_key = sys.argv[2]
    endpoint = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_ENDPOINT

    setup_appwrite(endpoint, project_id, api_key)
