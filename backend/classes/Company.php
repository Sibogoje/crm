<?php
class Company {
    private $conn;
    private $table_name = "companies";

    public $id;
    public $name;
    public $email;
    public $phone;
    public $address;
    public $tax_id;
    public $logo_path;
    public $currency;
    public $default_tax_rate;
    public $invoice_prefix;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                SET name=:name, email=:email, phone=:phone, 
                    address=:address, tax_id=:tax_id, logo_url=:logo_url,
                    currency=:currency, default_tax_rate=:default_tax_rate, 
                    invoice_prefix=:invoice_prefix";

        $stmt = $this->conn->prepare($query);

        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone = htmlspecialchars(strip_tags($this->phone));
        $this->address = htmlspecialchars(strip_tags($this->address));
        $this->tax_id = htmlspecialchars(strip_tags($this->tax_id));
        $this->logo_path = htmlspecialchars(strip_tags($this->logo_path));
        $this->currency = htmlspecialchars(strip_tags($this->currency));
        $this->default_tax_rate = htmlspecialchars(strip_tags($this->default_tax_rate));
        $this->invoice_prefix = htmlspecialchars(strip_tags($this->invoice_prefix));

        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":tax_id", $this->tax_id);
        $stmt->bindParam(":logo_url", $this->logo_path);
        $stmt->bindParam(":currency", $this->currency);
        $stmt->bindParam(":default_tax_rate", $this->default_tax_rate);
        $stmt->bindParam(":invoice_prefix", $this->invoice_prefix);

        if($stmt->execute()) {
            $this->id = $this->conn->lastInsertId();
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT * FROM " . $this->table_name . " LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                SET name=:name, email=:email, phone=:phone, 
                    address=:address, tax_id=:tax_id, logo_path=:logo_path,
                    currency=:currency, default_tax_rate=:default_tax_rate, 
                    invoice_prefix=:invoice_prefix
                WHERE id=:id";

        $stmt = $this->conn->prepare($query);

        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone = htmlspecialchars(strip_tags($this->phone));
        $this->address = htmlspecialchars(strip_tags($this->address));
        $this->tax_id = htmlspecialchars(strip_tags($this->tax_id));
        $this->logo_path = htmlspecialchars(strip_tags($this->logo_path));
        $this->currency = htmlspecialchars(strip_tags($this->currency));
        $this->default_tax_rate = htmlspecialchars(strip_tags($this->default_tax_rate));
        $this->invoice_prefix = htmlspecialchars(strip_tags($this->invoice_prefix));
        $this->id = htmlspecialchars(strip_tags($this->id));

        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":tax_id", $this->tax_id);
        $stmt->bindParam(":logo_path", $this->logo_path);
        $stmt->bindParam(":currency", $this->currency);
        $stmt->bindParam(":default_tax_rate", $this->default_tax_rate);
        $stmt->bindParam(":invoice_prefix", $this->invoice_prefix);
        $stmt->bindParam(":id", $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }
}
?>
