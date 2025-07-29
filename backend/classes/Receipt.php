<?php
class Receipt {
    private $conn;
    private $table_name = "receipts";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getAll($company_id) {
        $query = "SELECT r.*, i.invoice_number, c.name as client_name
                  FROM " . $this->table_name . " r
                  LEFT JOIN invoices i ON r.invoice_id = i.id
                  LEFT JOIN clients c ON i.client_id = c.id
                  WHERE r.company_id = ?
                  ORDER BY r.created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $company_id, PDO::PARAM_INT);
        $stmt->execute();

        $receipts = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $receipts[] = $row;
        }

        return $receipts;
    }

    public function getById($id, $company_id) {
        $query = "SELECT r.*, i.invoice_number, c.name as client_name
                  FROM " . $this->table_name . " r
                  LEFT JOIN invoices i ON r.invoice_id = i.id
                  LEFT JOIN clients c ON i.client_id = c.id
                  WHERE r.id = ? AND r.company_id = ?";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $id, PDO::PARAM_INT);
        $stmt->bindParam(2, $company_id, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function getByInvoiceId($invoice_id, $company_id) {
        $query = "SELECT r.*, i.invoice_number, c.name as client_name
                  FROM " . $this->table_name . " r
                  LEFT JOIN invoices i ON r.invoice_id = i.id
                  LEFT JOIN clients c ON i.client_id = c.id
                  WHERE r.invoice_id = ? AND r.company_id = ?
                  ORDER BY r.created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $invoice_id, PDO::PARAM_INT);
        $stmt->bindParam(2, $company_id, PDO::PARAM_INT);
        $stmt->execute();

        $receipts = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $receipts[] = $row;
        }

        return $receipts;
    }

    public function create($data) {
        // Generate receipt number if not provided
        $receipt_number = $data['receipt_number'] ?? $this->generateReceiptNumber($data['company_id']);

        $query = "INSERT INTO " . $this->table_name . " 
                  (company_id, invoice_id, receipt_number, amount, payment_method, payment_reference, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?)";

        $stmt = $this->conn->prepare($query);
        
        $company_id = $data['company_id'];
        $invoice_id = $data['invoice_id'];
        $amount = $data['amount'];
        $payment_method = $data['payment_method'] ?? 'cash';
        $payment_reference = $data['payment_reference'] ?? null;
        $notes = $data['notes'] ?? null;

        $stmt->bindParam(1, $company_id, PDO::PARAM_INT);
        $stmt->bindParam(2, $invoice_id, PDO::PARAM_INT);
        $stmt->bindParam(3, $receipt_number, PDO::PARAM_STR);
        $stmt->bindParam(4, $amount, PDO::PARAM_STR);
        $stmt->bindParam(5, $payment_method, PDO::PARAM_STR);
        $stmt->bindParam(6, $payment_reference, PDO::PARAM_STR);
        $stmt->bindParam(7, $notes, PDO::PARAM_STR);

        if ($stmt->execute()) {
            $receipt_id = $this->conn->lastInsertId();
            
            // Update the invoice paid amount and status
            $this->updateInvoicePayment($invoice_id, $amount);
            
            return $this->getById($receipt_id, $company_id);
        }

        return null;
    }

    public function update($id, $data) {
        $query = "UPDATE " . $this->table_name . " 
                  SET amount = ?, payment_method = ?, payment_reference = ?, notes = ?
                  WHERE id = ? AND company_id = ?";

        $stmt = $this->conn->prepare($query);
        
        $amount = $data['amount'];
        $payment_method = $data['payment_method'];
        $payment_reference = $data['payment_reference'] ?? null;
        $notes = $data['notes'] ?? null;
        $company_id = $data['company_id'];

        $stmt->bindParam(1, $amount, PDO::PARAM_STR);
        $stmt->bindParam(2, $payment_method, PDO::PARAM_STR);
        $stmt->bindParam(3, $payment_reference, PDO::PARAM_STR);
        $stmt->bindParam(4, $notes, PDO::PARAM_STR);
        $stmt->bindParam(5, $id, PDO::PARAM_INT);
        $stmt->bindParam(6, $company_id, PDO::PARAM_INT);

        if ($stmt->execute()) {
            return $this->getById($id, $company_id);
        }

        return null;
    }

    public function delete($id, $company_id) {
        // Get the receipt first to know which invoice to update
        $receipt = $this->getById($id, $company_id);
        if (!$receipt) {
            return false;
        }

        $query = "DELETE FROM " . $this->table_name . " WHERE id = ? AND company_id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $id, PDO::PARAM_INT);
        $stmt->bindParam(2, $company_id, PDO::PARAM_INT);

        if ($stmt->execute()) {
            // Update the invoice to subtract this payment
            $this->updateInvoicePayment($receipt['invoice_id'], -$receipt['amount']);
            return true;
        }

        return false;
    }

    private function updateInvoicePayment($invoice_id, $amount_change) {
        // Get current invoice details
        $query = "SELECT paid_amount, total FROM invoices WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $invoice_id, PDO::PARAM_INT);
        $stmt->execute();
        $invoice = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$invoice) {
            return false;
        }

        $new_paid_amount = $invoice['paid_amount'] + $amount_change;
        $new_paid_amount = max(0, $new_paid_amount); // Ensure non-negative

        // Determine new status
        $new_status = 'draft';
        if ($new_paid_amount >= $invoice['total']) {
            $new_status = 'paid';
        } elseif ($new_paid_amount > 0) {
            $new_status = 'sent'; // Partially paid
        }

        // Update invoice
        $update_query = "UPDATE invoices SET paid_amount = ?, status = ? WHERE id = ?";
        $update_stmt = $this->conn->prepare($update_query);
        $update_stmt->bindParam(1, $new_paid_amount, PDO::PARAM_STR);
        $update_stmt->bindParam(2, $new_status, PDO::PARAM_STR);
        $update_stmt->bindParam(3, $invoice_id, PDO::PARAM_INT);

        return $update_stmt->execute();
    }

    private function generateReceiptNumber($company_id) {
        $query = "SELECT COUNT(*) as count FROM " . $this->table_name . " WHERE company_id = ?";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $company_id, PDO::PARAM_INT);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $count = $row['count'] + 1;
        return 'REC-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }
}
?>
