module.exports = (collectionName, doc, recordCounters, writeRecord) => {
  // Transform the client document
  const transformedDoc = {
    id: doc.id,
    user_id: doc.userId,
    created_at: doc.createdAt,
    updated_at: doc.updatedAt,
    // Add other client-specific fields
  };

  return transformedDoc;
} 