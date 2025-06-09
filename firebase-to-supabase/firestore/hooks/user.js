module.exports = (collectionName, doc, recordCounters, writeRecord) => {
  // Transform the user document
  const transformedDoc = {
    id: doc.userId || doc.id,
    email: doc.email,
    created_at: doc.createdAt,
    updated_at: doc.updatedAt,
    user_code: doc.userCode,
    deleted: doc.deleted || false,
    reason_for_deletion: doc.reasonForAccountDeletion || null,
    // Add any other fields from your UserDto
  };

  return transformedDoc;
} 