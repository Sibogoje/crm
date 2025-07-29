<?php
class Client {
    private $conn;
    private $table_name = "clients";

    public $id;
    public $company_id;
    public $name;
    public $email;
    public $phone;
    public $address;
    public $tax_id;
    public $client_company;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                SET id=:id, company_id=:company_id, name=:name, email=:email, 
                    phone=:phone, address=:address, tax_id=:tax_id, 
                    client_company=:client_company";

        $stmt = $this->conn->prepare($query);

        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->company_id = htmlspecialchars(strip_tags($this->company_id));
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone = htmlspecialchars(strip_tags($this->phone));
        $this->address = htmlspecialchars(strip_tags($this->address));
        $this->tax_id = htmlspecialchars(strip_tags($this->tax_id));
        $this->client_company = htmlspecialchars(strip_tags($this->client_company));

        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":company_id", $this->company_id);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":tax_id", $this->tax_id);
        $stmt->bindParam(":client_company", $this->client_company);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function readAll($company_id) {
        $query = "SELECT * FROM " . $this->table_name . " 
                WHERE company_id = ? ORDER BY name ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $company_id);
        $stmt->execute();

        return $stmt;
    }

    public function readOne() {
        $query = "SELECT * FROM " . $this->table_name . " 
                WHERE id = ? AND company_id = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->bindParam(2, $this->company_id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if($row) {
            $this->name = $row['name'];
            $this->email = $row['email'];
            $this->phone = $row['phone'];
            $this->address = $row['address'];
            $this->tax_id = $row['tax_id'];
            $this->client_company = $row['client_company'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
        }
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                SET name=:name, email=:email, phone=:phone, 
                    address=:address, tax_id=:tax_id, client_company=:client_company
                WHERE id=:id AND company_id=:company_id";

        $stmt = $this->conn->prepare($query);

        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone = htmlspecialchars(strip_tags($this->phone));
        $this->address = htmlspecialchars(strip_tags($this->address));
        $this->tax_id = htmlspecialchars(strip_tags($this->tax_id));
        $this->client_company = htmlspecialchars(strip_tags($this->client_company));
        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->company_id = htmlspecialchars(strip_tags($this->company_id));

        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":tax_id", $this->tax_id);
        $stmt->bindParam(":client_company", $this->client_company);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":company_id", $this->company_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " 
                WHERE id = ? AND company_id = ?";

        $stmt = $this->conn->prepare($query);

        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->company_id = htmlspecialchars(strip_tags($this->company_id));

        $stmt->bindParam(1, $this->id);
        $stmt->bindParam(2, $this->company_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }
}
?>
