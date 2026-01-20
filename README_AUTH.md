# CBU Baseball Dashboard - Authentication Setup

## 🎯 Overview
Your dashboard now has a beautiful custom login page with secure user management and password reset functionality!

## 🚀 Quick Start

### 1. Install Required Packages
```r
install.packages("shinymanager")
install.packages("blastula")  # For password reset emails
```

### 2. Create Initial Credentials
Run the setup script once:
```r
source("setup_credentials.R")
```

This creates `credentials.sqlite` with these default users:
- **jgaynor@pitchingcoachu.com** / cbu2024 (Admin)
- **banni17@yahoo.com** / cbu2024 (Admin)
- **micaiahtucker@gmail.com** / cbu2024 (Admin)
- **joshtols21@gmail.com** / cbu2024 (Admin)
- **james.a.gaynor@gmail.com** / cbu2024 (Admin)
- **tblank@mariners.com** / cbu2024 (Admin)
- **admin** / admin123 (Admin - fallback)

### 3. Configure Email for Password Reset (Optional)
See the **Password Reset Setup** section below to enable "Forgot Password" functionality.

### 4. Run Your App
```r
shiny::runApp()
```

## 🔐 Security

### Change Default Passwords!
1. Log in with admin credentials
2. Click "Admin Panel" button (top right when logged in as admin)
3. Change all default passwords

### Keep Secret
- **credentials.sqlite** - Contains all user data
- **Passphrase**: `cbu_baseball_2024_secure_passphrase` (in app.R and setup script)

## 📧 Password Reset Setup

The "Forgot Password" button is now available on the login page! Users can reset their passwords via email.

### Configure Email Settings

#### Option 1: Using Gmail (Easiest for Testing)
1. Enable 2-factor authentication on your Gmail account
2. Generate an App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Name it "CBU Baseball App"
   - Copy the 16-character password
3. Edit your `.Renviron` file:
   ```r
   usethis::edit_r_environ()
   ```
4. Add these lines (replace with your info):
   ```
   MAIL_SERVER=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USERNAME=your-email@gmail.com
   MAIL_PASSWORD=your-16-char-app-password
   MAIL_FROM=your-email@gmail.com
   ```
5. Save, close, and restart R

#### Option 2: Using Custom SMTP Server
Edit your `.Renviron` file and add:
```
MAIL_SERVER=smtp.yourserver.com
MAIL_PORT=587
MAIL_USERNAME=your-username
MAIL_PASSWORD=your-password
MAIL_FROM=noreply@yourdomain.com
```

#### Option 3: On shinyapps.io
1. Go to your app on shinyapps.io
2. Click **Settings** → **Vars** tab
3. Add environment variables:
   - `MAIL_SERVER`
   - `MAIL_PORT`
   - `MAIL_USERNAME`
   - `MAIL_PASSWORD`
   - `MAIL_FROM`

### Test Email Configuration
```r
source("email_config.R")
test_email_config()
```

### How Password Reset Works
1. User clicks "Forgot Password" on login page
2. Enters their email address
3. Receives email with secure reset link
4. Clicks link to set new password
5. Can now log in with new password

**Note**: Email must match the email in the credentials database!

## 👥 Managing Users

### Option 1: Admin Panel (Recommended)
1. Log in as admin
2. Look for "Admin Panel" button
3. Add, edit, or delete users
4. Changes are saved immediately

### Option 2: Edit Setup Script
1. Edit `setup_credentials.R`
2. Add users to the `initial_users` data frame
3. Run the script again
4. Restart the app

## 📊 User Roles

### Admin Users
- Full access to all features
- Can access Admin Panel
- Can add/edit/delete other users
- Can view all player data

### Regular Users  
- Access based on email/permissions
- Cannot access Admin Panel
- Player-specific views (as configured)

## 🎨 Login Page Features

- Animated gradient background
- CBU logo branding
- Modern, professional design
- "Remember me" option
- Secure password handling

## 📤 Deploying to shinyapps.io

The `credentials.sqlite` file will be uploaded with your app.

**Before deploying:**
1. ✅ Change all default passwords
2. ✅ Add all actual users
3. ✅ Test locally
4. ✅ Deploy normally with `rsconnect::deployApp()`

## 🆘 Troubleshooting

### "Admin Panel" button not showing
- Make sure you're logged in with a user where `admin = TRUE`
- Check credentials.sqlite has the admin flag set

### Forgot admin password
- Delete `credentials.sqlite`
- Run `setup_credentials.R` again
- Log in with default admin credentials

### Can't log in
- Check that `credentials.sqlite` exists
- Verify username/password are correct
- Check console for error messages

## 📁 Files

- **app.R** - Main application (includes auth setup)
- **credentials.sqlite** - User database (created by setup script)
- **setup_credentials.R** - Script to initialize credentials
- **README_AUTH.md** - This file

## 🎓 Adding Your Baseball Team

Edit `setup_credentials.R` to add your players/coaches:

```r
initial_users <- data.frame(
  user = c("player_lastname", "coach_smith"),
  password = c("temp123", "temp456"),
  admin = c(FALSE, TRUE),
  email = c("player@school.edu", "coach@school.edu"),
  stringsAsFactors = FALSE
)
```

Then have them change their passwords on first login!

## 💡 Tips

1. **First time setup**: Use the setup script
2. **Adding users later**: Use the Admin Panel
3. **Password security**: Have users change default passwords immediately
4. **Backup**: Keep a copy of credentials.sqlite somewhere safe
5. **Testing**: Test with different user accounts before deploying

---

Need help? Contact: jgaynor@pitchingcoachu.com
