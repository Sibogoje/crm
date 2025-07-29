<?php
class Item {
    private $conn;
    private $table_name = "items";

    public $id;
    public $company_id;
    public $name;
    public $description;
    public $price;
    public $category;
    public $is_service;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                SET company_id=:company_id, name=:name, description=:description, 
                    price=:price, category=:category, is_service=:is_service";

        $stmt = $this->conn->prepare($query);

        $this->company_id = htmlspecialchars(strip_tags($this->company_id));
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->price = htmlspecialchars(strip_tags($this->price));
        $this->category = htmlspecialchars(strip_tags($this->category));
        $this->is_service = $this->is_service ? 1 : 0;

        $stmt->bindParam(":company_id", $this->company_id);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":price", $this->price);
        $stmt->bindParam(":category", $this->category);
        $stmt->bindParam(":is_service", $this->is_service);

        if($stmt->execute()) {
            $this->id = $this->conn->lastInsertId();
            return true;
        }
        return false;
    }

    public function read($company_id) {
        $query = "SELECT id, company_id, name, description, price, category, is_service, created_at, updated_at
                FROM " . $this->table_name . " 
                WHERE company_id = :company_id 
                ORDER BY name ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":company_id", $company_id);
        $stmt->execute();

        return $stmt;
    }

    public function readOne() {
        $query = "SELECT id, company_id, name, description, price, category, is_service, created_at, updated_at
                FROM " . $this->table_name . " 
                WHERE id = :id AND company_id = :company_id 
                LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":company_id", $this->company_id);
        $stmt->execute();

        $num = $stmt->rowCount();

        if($num > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->id = $row['id'];
            $this->company_id = $row['company_id'];
            $this->name = $row['name'];
            $this->description = $row['description'];
            $this->price = $row['price'];
            $this->category = $row['category'];
            $this->is_service = $row['is_service'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                SET name=:name, description=:description, price=:price, 
                    category=:category, is_service=:is_service, updated_at=CURRENT_TIMESTAMP
                WHERE id=:id AND company_id=:company_id";

        $stmt = $this->conn->prepare($query);

        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->price = htmlspecialchars(strip_tags($this->price));
        $this->category = htmlspecialchars(strip_tags($this->category));
        $this->is_service = $this->is_service ? 1 : 0;

        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":company_id", $this->company_id);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":price", $this->price);
        $stmt->bindParam(":category", $this->category);
        $stmt->bindParam(":is_service", $this->is_service);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " 
                WHERE id = :id AND company_id = :company_id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":company_id", $this->company_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }
}
?>
