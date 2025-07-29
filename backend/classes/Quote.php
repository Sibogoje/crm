<?php

class Quote {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
    }
    
    public function getAll($companyId) {
        try {
            $query = "SELECT q.*, c.name as client_name 
                     FROM quotes q 
                     LEFT JOIN clients c ON q.client_id = c.id 
                     WHERE q.company_id = ? 
                     ORDER BY q.created_at DESC";
            $stmt = $this->db->prepare($query);
            $stmt->execute([$companyId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("Quote getAll error: " . $e->getMessage());
            return [];
        }
    }
    
    public function getById($id, $companyId) {
        try {
            $query = "SELECT q.*, c.name as client_name 
                     FROM quotes q 
                     LEFT JOIN clients c ON q.client_id = c.id 
                     WHERE q.id = ? AND q.company_id = ?";
            $stmt = $this->db->prepare($query);
            $stmt->execute([$id, $companyId]);
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("Quote getById error: " . $e->getMessage());
            return null;
        }
    }
    
    public function create($data, $companyId) {
        try {
            $this->db->beginTransaction();
            
            // Calculate totals from items
            $items = $data['items'] ?? [];
            $subtotal = 0;
            foreach ($items as $item) {
                $subtotal += floatval($item['total_price'] ?? 0);
            }
            
            // Insert quote (keep items column for backward compatibility)
            $query = "INSERT INTO quotes (company_id, client_id, quote_number, quote_date, expiry_date, status, subtotal, tax_amount, total_amount, notes, items) 
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            $stmt = $this->db->prepare($query);
            $result = $stmt->execute([
                $companyId,
                $data['client_id'],
                $data['quote_number'],
                $data['quote_date'],
                $data['expiry_date'] ?? null,
                $data['status'] ?? 'draft',
                $data['subtotal'] ?? $subtotal,
                $data['tax_amount'] ?? 0,
                $data['total_amount'] ?? ($subtotal + floatval($data['tax_amount'] ?? 0)),
                $data['notes'] ?? null,
                json_encode($items) // Store items as JSON for backward compatibility
            ]);
            
            if (!$result) {
                throw new Exception("Failed to create quote");
            }
            
            $quoteId = $this->db->lastInsertId();
            
            // Insert quote items in separate table
            if (isset($data['items']) && is_array($data['items'])) {
                foreach ($data['items'] as $item) {
                    $this->createQuoteItem($quoteId, $item);
                }
            }
            
            $this->db->commit();
            
            // Return the created quote
            return $this->getById($quoteId, $companyId);
            
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("Quote create error: " . $e->getMessage());
            throw $e;
        }
    }
    
    public function update($id, $data, $companyId) {
        try {
            $this->db->beginTransaction();
            
            // Calculate totals from items
            $items = $data['items'] ?? [];
            $subtotal = 0;
            foreach ($items as $item) {
                $subtotal += floatval($item['total_price'] ?? 0);
            }
            
            // Update quote
            $query = "UPDATE quotes SET 
                        client_id = ?, 
                        quote_number = ?, 
                        quote_date = ?, 
                        expiry_date = ?, 
                        status = ?, 
                        subtotal = ?, 
                        tax_amount = ?, 
                        total_amount = ?, 
                        notes = ?,
                        items = ?,
                        updated_at = CURRENT_TIMESTAMP
                      WHERE id = ? AND company_id = ?";
            $stmt = $this->db->prepare($query);
            $result = $stmt->execute([
                $data['client_id'],
                $data['quote_number'],
                $data['quote_date'],
                $data['expiry_date'] ?? null,
                $data['status'] ?? 'draft',
                $data['subtotal'] ?? $subtotal,
                $data['tax_amount'] ?? 0,
                $data['total_amount'] ?? ($subtotal + floatval($data['tax_amount'] ?? 0)),
                $data['notes'] ?? null,
                json_encode($items), // Store items as JSON for backward compatibility
                $id,
                $companyId
            ]);
            
            if (!$result) {
                throw new Exception("Failed to update quote");
            }
            
            // Update quote items if provided
            if (isset($data['items']) && is_array($data['items'])) {
                // Delete existing items
                $this->deleteQuoteItems($id);
                
                // Insert new items
                foreach ($data['items'] as $item) {
                    $this->createQuoteItem($id, $item);
                }
            }
            
            $this->db->commit();
            
            // Return the updated quote
            return $this->getById($id, $companyId);
            
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("Quote update error: " . $e->getMessage());
            throw $e;
        }
    }
    
    public function delete($id, $companyId) {
        try {
            $query = "DELETE FROM quotes WHERE id = ? AND company_id = ?";
            $stmt = $this->db->prepare($query);
            return $stmt->execute([$id, $companyId]);
        } catch (Exception $e) {
            error_log("Quote delete error: " . $e->getMessage());
            return false;
        }
    }
    
    public function getQuoteItems($quoteId) {
        try {
            $query = "SELECT * FROM quote_items WHERE quote_id = ? ORDER BY id";
            $stmt = $this->db->prepare($query);
            $stmt->execute([$quoteId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("Quote getQuoteItems error: " . $e->getMessage());
            return [];
        }
    }
    
    private function createQuoteItem($quoteId, $itemData) {
        $query = "INSERT INTO quote_items (quote_id, item_id, item_name, description, unit_price, quantity, total_price) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)";
        $stmt = $this->db->prepare($query);
        return $stmt->execute([
            $quoteId,
            $itemData['item_id'] ?? null,
            $itemData['item_name'],
            $itemData['description'] ?? '',
            $itemData['unit_price'],
            $itemData['quantity'] ?? 1,
            $itemData['total_price']
        ]);
    }
    
    private function deleteQuoteItems($quoteId) {
        $query = "DELETE FROM quote_items WHERE quote_id = ?";
        $stmt = $this->db->prepare($query);
        return $stmt->execute([$quoteId]);
    }
    
    public function generateQuoteNumber($companyId) {
        try {
            // Get the highest quote number for this company
            $query = "SELECT quote_number FROM quotes WHERE company_id = ? ORDER BY id DESC LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->execute([$companyId]);
            $lastQuote = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($lastQuote && preg_match('/QUO-(\d+)/', $lastQuote['quote_number'], $matches)) {
                $nextNumber = intval($matches[1]) + 1;
            } else {
                $nextNumber = 1;
            }
            
            return 'QUO-' . str_pad($nextNumber, 4, '0', STR_PAD_LEFT);
        } catch (Exception $e) {
            error_log("Quote generateQuoteNumber error: " . $e->getMessage());
            return 'QUO-0001';
        }
    }
}
?>
