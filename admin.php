<?php
require 'config.php';
if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'admin') {
    header("Location: index.php");
    exit();
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['update_issue'])) {
    $issue_id = $_POST['issue_id'];
    $department = $_POST['department'];
    $status = $_POST['status'];

    $conn->query("UPDATE issues SET department='$department', status='$status' WHERE id='$issue_id'");
}

$total = $conn->query("SELECT COUNT(*) as count FROM issues")->fetch_assoc()['count'];
$pending = $conn->query("SELECT COUNT(*) as count FROM issues WHERE status='Pending'")->fetch_assoc()['count'];
$progress = $conn->query("SELECT COUNT(*) as count FROM issues WHERE status='In Progress'")->fetch_assoc()['count'];
$resolved = $conn->query("SELECT COUNT(*) as count FROM issues WHERE status='Resolved'")->fetch_assoc()['count'];

$issues = $conn->query("SELECT issues.*, users.name as reporter FROM issues JOIN users ON issues.user_id = users.id ORDER BY created_at DESC");
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard - CrowdSignal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="navbar">
        <h2>📡 CrowdSignal - Admin Portal</h2>
        <div>
            <span style="margin-right: 1rem;">Admin: <?php echo $_SESSION['name']; ?></span>
            <a href="logout.php">Logout</a>
        </div>
    </div>

    <div class="container">
        <div class="stats-grid">
            <div class="stat-card"><h3><?php echo $total; ?></h3><p>Total Issues</p></div>
            <div class="stat-card"><h3 style="color: var(--pending);"><?php echo $pending; ?></h3><p>Pending</p></div>
            <div class="stat-card"><h3 style="color: var(--progress);"><?php echo $progress; ?></h3><p>In Progress</p></div>
            <div class="stat-card"><h3 style="color: var(--resolved);"><?php echo $resolved; ?></h3><p>Resolved</p></div>
        </div>

        <h3>All Campus Complaints</h3>
        <table style="margin-top: 1rem;">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Photo</th>
                    <th>Issue Details</th>
                    <th>Reporter & Location</th>
                    <th>Current Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <?php while($row = $issues->fetch_assoc()): ?>
                <tr>
                    <td>#<?php echo $row['id']; ?></td>
                    <td>
                        <?php if($row['image_path']): ?>
                            <a href="<?php echo $row['image_path']; ?>" target="_blank">
                                <img src="<?php echo $row['image_path']; ?>" class="issue-img">
                            </a>
                        <?php else: ?> N/A <?php endif; ?>
                    </td>
                    <td>
                        <strong><?php echo $row['title']; ?></strong> <span style="color:gray;">(<?php echo $row['category']; ?>)</span>
                        <p style="font-size: 0.9rem; margin-top: 5px;"><?php echo $row['description']; ?></p>
                    </td>
                    <td>
                        <strong>By:</strong> <?php echo $row['reporter']; ?><br>
                        <strong>Loc:</strong> <?php echo $row['location']; ?><br>
                        <small style="color:gray;"><?php echo date('d M Y, h:i A', strtotime($row['created_at'])); ?></small>
                    </td>
                    <td>
                        <?php $statusClass = str_replace(' ', '-', $row['status']); ?>
                        <span class="badge status-<?php echo $statusClass; ?>"><?php echo $row['status']; ?></span><br>
                        <small style="display:block; margin-top:5px;"><strong>Dept:</strong> <?php echo $row['department']; ?></small>
                    </td>
                    <td>
                        <form method="POST" style="display: flex; gap: 5px; flex-direction: column;">
                            <input type="hidden" name="issue_id" value="<?php echo $row['id']; ?>">
                            
                            <select name="department" style="padding: 5px;">
                                <option value="Unassigned" <?php if($row['department']=='Unassigned') echo 'selected'; ?>>Assign Dept...</option>
                                <option value="IT Support" <?php if($row['department']=='IT Support') echo 'selected'; ?>>IT Support</option>
                                <option value="Electrical Maintenance" <?php if($row['department']=='Electrical Maintenance') echo 'selected'; ?>>Electrical</option>
                                <option value="Plumbing" <?php if($row['department']=='Plumbing') echo 'selected'; ?>>Plumbing</option>
                                <option value="Civil / Housekeeping" <?php if($row['department']=='Civil / Housekeeping') echo 'selected'; ?>>Civil / Housekeeping</option>
                            </select>

                            <select name="status" style="padding: 5px;">
                                <option value="Pending" <?php if($row['status']=='Pending') echo 'selected'; ?>>Pending</option>
                                <option value="In Progress" <?php if($row['status']=='In Progress') echo 'selected'; ?>>In Progress</option>
                                <option value="Resolved" <?php if($row['status']=='Resolved') echo 'selected'; ?>>Resolved</option>
                            </select>

                            <button type="submit" name="update_issue" style="padding: 5px; font-size: 0.85rem;">Update</button>
                        </form>
                    </td>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
