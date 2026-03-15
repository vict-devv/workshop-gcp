import functions_framework
from google.cloud import firestore
import json

# Initialize Firestore Client
# Cloud Functions will use Application Default Credentials automatically
db = firestore.Client()
COLLECTION_NAME = 'books'

@functions_framework.http
def handler(request):
    """
    Main entry point for the Serverless CRUD API.
    Handles GET, POST, PUT, and DELETE for the 'books' collection.
    """
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
        }
    
    # Handle CORS (Cross-Origin Resource Sharing)
    if request.method == 'OPTIONS':
        return ('', 204, {
            **headers,
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
            'Access-Control-Allow-Headers': 'Content-Type'
        })

    # Extract ID from path if present (e.g., /book-id-123)
    path_parts = request.path.strip("/").split("/")
    doc_id = path_parts[0] if path_parts[0] else None

    try:
        # 1. CREATE (POST)
        if request.method == 'POST':
            payload = request.get_json(silent=True)
            if not payload or 'title' not in payload:
                return (json.dumps({"error": "Missing required field: title"}), 400, headers)
            
            payload['created_at'] = firestore.SERVER_TIMESTAMP
            _, doc_ref = db.collection(COLLECTION_NAME).add(payload)
            return (json.dumps({"id": doc_ref.id, "status": "Created"}), 201, headers)

        # 2. READ ALL or READ BY ID (GET)
        elif request.method == 'GET':
            if doc_id:
                doc = db.collection(COLLECTION_NAME).document(doc_id).get()
                if doc.exists:
                    return (json.dumps(doc.to_dict(), default=str), 200, headers)
                return (json.dumps({"error": "Book not found"}), 404, headers)
            
            # List all books
            docs = db.collection(COLLECTION_NAME).stream()
            results = {d.id: d.to_dict() for d in docs}
            return (json.dumps(results, default=str), 200, headers)

        # 3. UPDATE (PUT)
        elif request.method == 'PUT':
            if not doc_id:
                return (json.dumps({"error": "Document ID required for update"}), 400, headers)
            
            payload = request.get_json(silent=True)
            if not payload:
                return (json.dumps({"error": "Invalid JSON"}), 400, headers)
            
            # Full overwrite of existing document
            doc_ref = db.collection(COLLECTION_NAME).document(doc_id)
            doc_ref.set(payload)
            return (json.dumps({"status": "Updated", "id": doc_id}), 200, headers)

        # 4. DELETE (DELETE)
        elif request.method == 'DELETE':
            if not doc_id:
                return (json.dumps({"error": "Document ID required for deletion"}), 400, headers)
            
            db.collection(COLLECTION_NAME).document(doc_id).delete()
            return (json.dumps({"status": "Deleted", "id": doc_id}), 200, headers)

    except Exception as e:
        # Standard error logging for Cloud Logging
        print(f"Error processing request: {str(e)}")
        return (json.dumps({"error": "Internal Server Error"}), 500, headers)

    return ("Method Not Allowed", 405, headers)