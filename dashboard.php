<?php
require 'config.php';
if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'user') {
    header("Location: index.php");
    exit();
}

$user_id = $_SESSION['user_id'];
$msg = "";

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['submit_issue'])) {
    $title = $conn->real_escape_string($_POST['title']);
    $category = $conn->real_escape_string($_POST['category']);
    $location = $conn->real_escape_string($_POST['location']);
    $description = $conn->real_escape_string($_POST['description']);
    
    $image_path = "";
    if (!empty($_FILES['image']['name'])) {
        $target_dir = "uploads/";
        $image_path = $target_dir . time() . "_" . basename($_FILES["image"]["name"]);
        move_uploaded_file($_FILES["image"]["tmp_name"], $image_path);
    }

    $sql = "INSERT INTO issues (user_id, title, category, location, description, image_path) 
            VALUES ('$user_id', '$title', '$category', '$location', '$description', '$image_path')";
    
    if ($conn->query($sql)) {
        $msg = "Issue reported successfully!";
    } else {
        $msg = "Error reporting issue.";
    }
}

$issues = $conn->query("SELECT * FROM issues WHERE user_id='$user_id' ORDER BY created_at DESC");
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User Dashboard - CrowdSignal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="navbar">
        <h2>📡 CrowdSignal</h2>
        <div>
            <span style="margin-right: 1rem;">Welcome, <?php echo $_SESSION['name']; ?></span>
            <a href="logout.php">Logout</a>
        </div>
    </div>

    <div class="container">
        <div class="card">
            <h3 style="margin-bottom: 1rem;">Report a Campus Issue</h3>
            <?php if($msg) echo "<p style='color:green; margin-bottom:1rem;'>$msg</p>"; ?>
            <form method="POST" enctype="multipart/form-data">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                    <div class="form-group">
                        <label>Issue Title</label>
                        <input type="text" name="title" placeholder="e.g., Projector not working" required>
                    </div>
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category" required>
                            <option value="Electrical">Electrical</option>
                            <option value="IT / Projector">IT / Projector</option>
                            <option value="Plumbing / Water">Plumbing / Water</option>
                            <option value="Lab Equipment">Lab Equipment</option>
                            <option value="Furniture / Civil">Furniture / Civil</option>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label>Exact Location</label>
                    <input type="text" name="location" placeholder="e.g., Block B, Room 204" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3" placeholder="Describe the problem in detail..." required></textarea>
                </div>
                <div class="form-group">
                    <label>Upload Photo (Optional)</label>
                    <input type="file" name="image" accept="image/*" onchange="previewImage(event)">
                    <img id="img-preview" style="display:none; width: 100px; margin-top: 10px; border-radius: 5px;">
                </div>
                <button type="submit" name="submit_issue" style="width: auto;">Submit Report</button>
            </form>
        </div>

        <h3>My Reported Issues</h3>
        <table style="margin-top: 1rem;">
            <thead>
                <tr>
                    <th>Image</th>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Location</th>
                    <th>Assigned Dept.</th>
                    <th>Status</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                <?php while($row = $issues->fetch_assoc()): ?>
                <tr>
                    <td>
                        <?php if($row['image_path']): ?>
                            <a href="<?php echo $row['image_path']; ?>" target="_blank">
                                <img src="<?php echo $row['image_path']; ?>" class="issue-img">
                            </a>
                        <?php else: ?> No Image <?php endif; ?>
                    </td>
                    <td><strong><?php echo $row['title']; ?></strong><br><small><?php echo $row['description']; ?></small></td>
                    <td><?php echo $row['category']; ?></td>
                    <td><?php echo $row['location']; ?></td>
                    <td><?php echo $row['department']; ?></td>
                    <td>
                        <?php $statusClass = str_replace(' ', '-', $row['status']); ?>
                        <span class="badge status-<?php echo $statusClass; ?>"><?php echo $row['status']; ?></span>
                    </td>
                    <td><?php echo date('d M Y', strtotime($row['created_at'])); ?></td>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
    <script src="script.js"></script>
</body>
</html>
