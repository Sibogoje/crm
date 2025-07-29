<?php
class Invoice {
    private $conn;
    private $table_name = "invoices";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getAll($company_id) {
        $query = "SELECT i.*, c.name as client_name
                  FROM " . $this->table_name . " i
                  LEFT JOIN clients c ON i.client_id = c.id
                  WHERE i.company_id = ?
                  ORDER BY i.created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $company_id, PDO::PARAM_INT);
        $stmt->execute();

        $invoices = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $invoice_data = $row;
            $invoice_data['items'] = $this->getInvoiceItems($row['id']);
            $invoices[] = $invoice_data;
        }

        return $invoices;
    }

    public function getById($id, $company_id) {
        $query = "SELECT i.*, c.name as client_name
                  FROM " . $this->table_name . " i
                  LEFT JOIN clients c ON i.client_id = c.id
                  WHERE i.id = ? AND c.company_id = ?";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $id, PDO::PARAM_INT);
        $stmt->bindParam(2, $company_id, PDO::PARAM_INT);
        $stmt->execute();

        $invoice = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($invoice) {
            $invoice['items'] = $this->getInvoiceItems($id);
            return $invoice;
        }

        return null;
    }

    private function getInvoiceItems($invoice_id) {
        // The items are stored as JSON in the items column of the invoices table
        $query = "SELECT items FROM " . $this->table_name . " WHERE id = ?";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $invoice_id, PDO::PARAM_INT);
        $stmt->execute();

        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($result && $result['items']) {
            $items_data = json_decode($result['items'], true);
            if (is_array($items_data)) {
                return $items_data;
            }
        }

        return [];
    }

    public function create($data) {
        // Generate invoice number if not provided
        $invoice_number = $data['invoice_number'] ?? $this->generateInvoiceNumber($data['company_id']);

        $query = "INSERT INTO " . $this->table_name . " 
                  (company_id, client_id, quote_id, invoice_number, due_date, status, subtotal, tax_amount, total, paid_amount, notes, items)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        $stmt = $this->conn->prepare($query);
        
        $company_id = $data['company_id'];
        $client_id = $data['client_id'];
        $quote_id = $data['quote_id'] ?? null;
        $due_date = $data['due_date'] ?? null;
        $status = $data['status'] ?? 'draft';
        $subtotal = $data['subtotal'];
        $tax_amount = $data['tax_amount'];
        $total = $data['total'] ?? $data['total_amount'] ?? 0; // Handle both field names
        $paid_amount = $data['paid_amount'] ?? 0;
        $notes = $data['notes'] ?? null;
        $items_json = isset($data['items']) ? json_encode($data['items']) : '[]';

        $stmt->bindParam(1, $company_id, PDO::PARAM_INT);
        $stmt->bindParam(2, $client_id, PDO::PARAM_INT);
        $stmt->bindParam(3, $quote_id, PDO::PARAM_INT);
        $stmt->bindParam(4, $invoice_number, PDO::PARAM_STR);
        $stmt->bindParam(5, $due_date, PDO::PARAM_STR);
        $stmt->bindParam(6, $status, PDO::PARAM_STR);
        $stmt->bindParam(7, $subtotal, PDO::PARAM_STR);
        $stmt->bindParam(8, $tax_amount, PDO::PARAM_STR);
        $stmt->bindParam(9, $total, PDO::PARAM_STR);
        $stmt->bindParam(10, $paid_amount, PDO::PARAM_STR);
        $stmt->bindParam(11, $notes, PDO::PARAM_STR);
        $stmt->bindParam(12, $items_json, PDO::PARAM_STR);

        if ($stmt->execute()) {
            $invoice_id = $this->conn->lastInsertId();
            return $this->getById($invoice_id, $company_id);
        }

        return null;
    }

    public function createFromQuote($quote_id, $company_id) {
        // Get the quote data
        $quote_query = "SELECT q.*, c.name as client_name
                        FROM quotes q
                        LEFT JOIN clients c ON q.client_id = c.id
                        WHERE q.id = ? AND q.company_id = ?";

        try {
            $stmt = $this->conn->prepare($quote_query);
            $stmt->bindParam(1, $quote_id, PDO::PARAM_INT);
            $stmt->bindParam(2, $company_id, PDO::PARAM_INT);
            $stmt->execute();

            $quote = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$quote) {
                return null;
            }

            // Get quote items
            $items_query = "SELECT qi.*, i.name as item_name, i.description
                            FROM quote_items qi
                            LEFT JOIN items i ON qi.item_id = i.id
                            WHERE qi.quote_id = ?";

            $stmt = $this->conn->prepare($items_query);
            $stmt->bindParam(1, $quote_id, PDO::PARAM_INT);
            $stmt->execute();

            $quote_items = [];
            $subtotal = 0;
            while ($item = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $total_price = $item['unit_price'] * $item['quantity'];
                $subtotal += $total_price;
                
                $quote_items[] = [
                    'item_id' => $item['item_id'],
                    'item_name' => $item['item_name'] ?? 'Custom Item',
                    'description' => $item['description'] ?? '',
                    'unit_price' => $item['unit_price'],
                    'quantity' => $item['quantity'],
                    'total_price' => $total_price
                ];
            }

            // Calculate tax (assuming 10% for now, this could be configurable)
            $tax_rate = 0.10;
            $tax_amount = $subtotal * $tax_rate;
            $total_amount = $subtotal + $tax_amount;

            // Calculate due date (30 days from today)
            $due_date = date('Y-m-d', strtotime('+30 days'));

            // Create invoice data
            $invoice_data = [
                'company_id' => $company_id,
                'client_id' => $quote['client_id'],
                'quote_id' => $quote_id,
                'due_date' => $due_date,
                'status' => 'draft',
                'subtotal' => $subtotal,
                'tax_amount' => $tax_amount,
                'total' => $total_amount,
                'paid_amount' => 0,
                'notes' => $quote['notes'],
                'items' => $quote_items
            ];

            return $this->create($invoice_data);
        } catch (Exception $e) {
            error_log("Error in createFromQuote: " . $e->getMessage());
            throw $e;
        }
    }

    public function update($id, $data) {
        $query = "UPDATE " . $this->table_name . " 
                  SET client_id = ?, invoice_number = ?, due_date = ?, 
                      status = ?, subtotal = ?, tax_amount = ?, total = ?, 
                      paid_amount = ?, notes = ?, items = ?, updated_at = CURRENT_TIMESTAMP
                  WHERE id = ?";

        $stmt = $this->conn->prepare($query);
        
        $client_id = $data['client_id'];
        $invoice_number = $data['invoice_number'];
        $due_date = $data['due_date'] ?? null;
        $status = $data['status'];
        $subtotal = $data['subtotal'];
        $tax_amount = $data['tax_amount'];
        $total = $data['total'] ?? $data['total_amount'] ?? 0;
        $paid_amount = $data['paid_amount'] ?? 0;
        $notes = $data['notes'] ?? null;
        $items_json = isset($data['items']) ? json_encode($data['items']) : '[]';

        $stmt->bindParam(1, $client_id, PDO::PARAM_INT);
        $stmt->bindParam(2, $invoice_number, PDO::PARAM_STR);
        $stmt->bindParam(3, $due_date, PDO::PARAM_STR);
        $stmt->bindParam(4, $status, PDO::PARAM_STR);
        $stmt->bindParam(5, $subtotal, PDO::PARAM_STR);
        $stmt->bindParam(6, $tax_amount, PDO::PARAM_STR);
        $stmt->bindParam(7, $total, PDO::PARAM_STR);
        $stmt->bindParam(8, $paid_amount, PDO::PARAM_STR);
        $stmt->bindParam(9, $notes, PDO::PARAM_STR);
        $stmt->bindParam(10, $items_json, PDO::PARAM_STR);
        $stmt->bindParam(11, $id, PDO::PARAM_INT);

        if ($stmt->execute()) {
            return $this->getById($id, $data['company_id']);
        }

        return null;
    }

    public function delete($id, $company_id) {
        // Verify the invoice belongs to the company
        $verify_query = "SELECT i.id FROM " . $this->table_name . " i
                         LEFT JOIN clients c ON i.client_id = c.id
                         WHERE i.id = ? AND c.company_id = ?";
        
        $stmt = $this->conn->prepare($verify_query);
        $stmt->bindParam(1, $id, PDO::PARAM_INT);
        $stmt->bindParam(2, $company_id, PDO::PARAM_INT);
        $stmt->execute();

        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$result) {
            return false;
        }

        $query = "DELETE FROM " . $this->table_name . " WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $id, PDO::PARAM_INT);

        return $stmt->execute();
    }

    private function generateInvoiceNumber($company_id) {
        $query = "SELECT COUNT(*) as count FROM " . $this->table_name . " i
                  LEFT JOIN clients c ON i.client_id = c.id
                  WHERE c.company_id = ?";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $company_id, PDO::PARAM_INT);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $count = $row['count'] + 1;
        return 'INV-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }
}
?>
