<?php
// Turn off automatic exceptions so PHP doesn't crash on connection
mysqli_report(MYSQLI_REPORT_OFF);

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$host = '127.0.0.1';
$user = 'root';
$pass = 'root';
$port = 8889;

// Connect to MySQL SERVER ONLY (notice NO database name parameter)
$conn = @new mysqli($host, $user, $pass, '', $port);

// If port 8889 fails, try default port 3306
if ($conn->connect_error) {
    $port = 3306;
    $pass = '';
    $conn = @new mysqli($host, $user, $pass, '', $port);
}

if ($conn->connect_error) {
    die("<h2 style='color:red;'>MySQL Connection Failed!</h2><p>Make sure MySQL Server is running in the MAMP application.</p>");
}

// Automatically create Database
$conn->query("CREATE DATABASE IF NOT EXISTS `crowdsignal_db`");
$conn->select_db("crowdsignal_db");

// Automatically create Users Table
$conn->query("CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");

// Automatically create Issues Table
$conn->query("CREATE TABLE IF NOT EXISTS issues (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    location VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    image_path VARCHAR(255) DEFAULT NULL,
    department VARCHAR(50) DEFAULT 'Unassigned',
    status ENUM('Pending', 'In Progress', 'Resolved') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
)");
?>
