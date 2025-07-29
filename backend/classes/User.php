<?php
class User {
    private $conn;
    private $table_name = "users";

    public $id;
    public $company_id;
    public $email;
    public $password_hash;
    public $first_name;
    public $last_name;
    public $role;
    public $is_active;
    public $reset_token;
    public $reset_token_expires_at;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                SET company_id=:company_id, email=:email, 
                    password=:password_hash, first_name=:first_name, 
                    last_name=:last_name, role=:role";

        $stmt = $this->conn->prepare($query);

        $this->company_id = htmlspecialchars(strip_tags($this->company_id));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->password_hash = htmlspecialchars(strip_tags($this->password_hash));
        $this->first_name = htmlspecialchars(strip_tags($this->first_name));
        $this->last_name = htmlspecialchars(strip_tags($this->last_name));
        $this->role = htmlspecialchars(strip_tags($this->role));

        $stmt->bindParam(":company_id", $this->company_id);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":password_hash", $this->password_hash);
        $stmt->bindParam(":first_name", $this->first_name);
        $stmt->bindParam(":last_name", $this->last_name);
        $stmt->bindParam(":role", $this->role);

        if($stmt->execute()) {
            $this->id = $this->conn->lastInsertId();
            return true;
        }
        return false;
    }

    public function emailExists() {
        $query = "SELECT id, company_id, email, password, first_name, last_name, role 
                FROM " . $this->table_name . " 
                WHERE email = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->email);
        $stmt->execute();

        $num = $stmt->rowCount();

        if($num > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->id = $row['id'];
            $this->company_id = $row['company_id'];
            $this->email = $row['email'];
            $this->password_hash = $row['password'];
            $this->first_name = $row['first_name'];
            $this->last_name = $row['last_name'];
            $this->role = $row['role'];
            return true;
        }
        return false;
    }

    public function verifyPassword($password) {
        return password_verify($password, $this->password_hash);
    }

    public function createPasswordResetToken() {
        $query = "UPDATE " . $this->table_name . " 
                SET reset_token = :reset_token, 
                    reset_token_expires_at = DATE_ADD(NOW(), INTERVAL 1 HOUR)
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        $this->reset_token = htmlspecialchars(strip_tags($this->reset_token));
        $this->id = htmlspecialchars(strip_tags($this->id));

        $stmt->bindParam(':reset_token', $this->reset_token);
        $stmt->bindParam(':id', $this->id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function isResetTokenValid($token) {
        $query = "SELECT id FROM " . $this->table_name . " 
                  WHERE reset_token = :token AND reset_token_expires_at > NOW()";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':token', $token);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            return $row['id'];
        }
        return false;
    }

    public function updatePassword($id, $password) {
        $query = "UPDATE " . $this->table_name . " 
                  SET password = :password_hash,
                      reset_token = NULL,
                      reset_token_expires_at = NULL
                  WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        $password_hash = password_hash($password, PASSWORD_BCRYPT);

        $stmt->bindParam(':password_hash', $password_hash);
        $stmt->bindParam(':id', $id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function deleteResetToken($token) {
        $query = "UPDATE " . $this->table_name . " 
                  SET reset_token = NULL, reset_token_expires_at = NULL 
                  WHERE reset_token = :token";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':token', $token);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }
}
?>
