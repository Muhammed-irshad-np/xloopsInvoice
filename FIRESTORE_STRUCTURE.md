# Firestore Database Structure

This document describes how the Firestore database is structured to match the application models.

## Collections

### 1. `customers` Collection

**Document ID**: Customer ID (String)

**Document Fields**:
```json
{
  "id": "string",
  "companyName": "string",
  "country": "string",
  "vatRegisteredInKSA": boolean,
  "taxRegistrationNumber": "string",
  "city": "string",
  "streetAddress": "string",
  "buildingNumber": "string",
  "district": "string",
  "addressAdditionalNumber": "string | null",
  "postalCode": "string"
}
```

**Indexes Required**:
- `companyName` (ASC) - for ordering customers alphabetically

**Operations**:
- Create: `insertCustomer()` - stores customer with ID as document ID
- Read All: `getAllCustomers()` - queries with `orderBy('companyName')`
- Read One: `getCustomerById()` - gets document by ID
- Update: `updateCustomer()` - updates document by ID
- Delete: `deleteCustomer()` - deletes document by ID

---

### 2. `invoices` Collection

**Document ID**: Invoice ID (String - typically timestamp-based)

**Document Fields**:
```json
{
  "id": "string",
  "date": Timestamp,
  "createdAt": Timestamp,
  "invoiceNumber": "string",
  "contractReference": "string",
  "paymentTerms": "string",
  "customerId": "string | null",
  "taxRate": number,
  "discount": number,
  "lineItems": [
    {
      "description": "string",
      "unit": "string",
      "unitType": "string",
      "referenceCode": "string | null",
      "subtotalAmount": number,
      "totalAmount": number
    }
  ]
}
```

**Notes**:
- `date` is stored as Firestore Timestamp (converted from DateTime)
- `customerId` is a reference to the customer document (customer object is NOT stored to avoid redundancy)
- `lineItems` is stored as a nested array (not a separate collection)
- Customer data is fetched separately using `customerId` when reading invoices

**Indexes Required**:
- `date` (DESC) - for ordering invoices by date
- Composite index may be needed if filtering by date range + ordering by date (Firestore will auto-create if needed)

**Operations**:
- Create: `insertInvoice()` - stores invoice with nested lineItems array
- Read All: `getAllInvoices()` - queries with optional date filtering and orders by date DESC
- Read Filtered: `getAllInvoices(month, year)` - filters by date range
- Delete: `deleteInvoice()` - deletes invoice document (lineItems are nested, so deleted automatically)
- Generate Number: `generateNewInvoiceNumber()` - queries invoices by year prefix to generate sequential numbers

---

## Data Flow

### Saving an Invoice:
1. InvoiceModel.toJson() is called (includes lineItems, excludes customer object)
2. Customer object is removed from invoiceData
3. Date is converted to Timestamp
4. customerId is added as reference
5. createdAt timestamp is added
6. Document is saved to `invoices` collection

### Reading an Invoice:
1. Invoice document is fetched from Firestore
2. customerId is extracted
3. Customer is fetched separately from `customers` collection using customerId
4. lineItems array is extracted and converted to LineItemModel objects
5. Date Timestamp is converted back to DateTime (millisecondsSinceEpoch)
6. InvoiceModel is reconstructed with customer and lineItems

---

## Model Mapping

### CustomerModel ↔ Firestore `customers` Collection
- ✅ Direct mapping - all fields stored as-is
- ✅ Boolean values stored as boolean (not 1/0)
- ✅ Nullable fields stored as null when empty

### InvoiceModel ↔ Firestore `invoices` Collection
- ✅ Most fields stored directly
- ✅ Date converted: DateTime → Timestamp (on save), Timestamp → DateTime (on read)
- ✅ Customer stored as reference (customerId) only, not embedded object
- ✅ LineItems stored as nested array

### LineItemModel ↔ Firestore Nested Array
- ✅ Stored as nested objects within invoice document
- ✅ All fields stored directly
- ✅ No separate collection needed

---

## Query Patterns

### Get All Customers (Ordered)
```dart
collection('customers').orderBy('companyName').get()
```

### Get All Invoices (Ordered by Date)
```dart
collection('invoices').orderBy('date', descending: true).get()
```

### Get Invoices by Month/Year
```dart
collection('invoices')
  .where('date', isGreaterThanOrEqualTo: startTimestamp)
  .where('date', isLessThan: endTimestamp)
  .orderBy('date', descending: true)
  .get()
```

### Generate Invoice Number
```dart
collection('invoices')
  .where('invoiceNumber', isGreaterThanOrEqualTo: 'INT-2024-')
  .where('invoiceNumber', isLessThan: 'INT-2025-')
  .get()
```

---

## Security Rules

Current rules allow read/write for all (suitable for single-user app):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## Summary

✅ **Customers**: Stored as separate documents, directly mapped from CustomerModel
✅ **Invoices**: Stored as separate documents with nested lineItems array
✅ **Line Items**: Stored as nested array within invoice documents (not separate collection)
✅ **Relationships**: Customer-Invoice relationship via customerId reference
✅ **Date Handling**: Properly converted between DateTime and Firestore Timestamp
✅ **Data Integrity**: Customer data always fetched fresh (not stored redundantly in invoices)

The database structure matches the application models perfectly!

