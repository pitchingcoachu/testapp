# Password Reset Feature - Quick Guide

## ✅ What's Been Added

Your CBU Baseball Dashboard now has a **"Forgot Password"** button on the login page!

### Features:
- 🔑 Users can reset their own passwords via email
- 📧 Secure password reset links sent automatically
- 💅 Styled to match your beautiful login page
- 🔒 Email must match the email in the credentials database

## 🚀 How to Enable Email Sending

The "Forgot Password" button appears automatically, but you need to configure email settings for it to work.

### Quick Setup with Gmail

1. **Enable 2-Factor Authentication** on your Gmail account

2. **Create an App Password**:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Name it "CBU Baseball App"
   - Copy the 16-character password (looks like: `abcd efgh ijkl mnop`)

3. **Configure Environment Variables**:
   ```r
   # Open your R environment file
   usethis::edit_r_environ()
   ```
   
   Add these lines (replace with your info):
   ```
   MAIL_SERVER=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USERNAME=your-email@gmail.com
   MAIL_PASSWORD=abcdefghijklmnop
   MAIL_FROM=your-email@gmail.com
   ```

4. **Save, close the file, and restart R**

5. **Test the configuration**:
   ```r
   source("email_config.R")
   test_email_config()
   ```

## 📱 For shinyapps.io Deployment

When you deploy to shinyapps.io:

1. Go to your app settings on shinyapps.io
2. Click **Settings** → **Vars** tab
3. Add these environment variables:
   - `MAIL_SERVER` = `smtp.gmail.com`
   - `MAIL_PORT` = `587`
   - `MAIL_USERNAME` = your Gmail address
   - `MAIL_PASSWORD` = your 16-char app password
   - `MAIL_FROM` = your Gmail address

## 🎯 How It Works

1. User clicks **"Forgot Password"** on login page
2. Enters their email address (must match email in database)
3. Receives an email with a secure reset link
4. Clicks the link to set a new password
5. Can now log in with the new password

## ⚠️ Important Notes

- Email address must match what's in the credentials database
- Users created via Admin Panel must have valid email addresses
- Gmail App Passwords are different from your regular Gmail password
- The reset link expires after a certain time for security

## 🧪 Testing Locally

1. Configure email settings (see above)
2. Run your app: `shiny::runApp()`
3. Click "Forgot Password"
4. Enter an admin email (e.g., `jgaynor@pitchingcoachu.com`)
5. Check your email inbox for the reset link
6. Click the link and set a new password

## 📚 Files Modified

- **app.R**: Added `enable_reset_password = TRUE` and email configuration
- **README_AUTH.md**: Updated with password reset documentation
- **email_config.R**: Created - email setup helper and testing
- **install_email_package.R**: Created - installs blastula package

## 🆘 Troubleshooting

**"Forgot Password button doesn't do anything"**
- Email settings are not configured
- Run `test_email_config()` to check

**"Email not received"**
- Check spam/junk folder
- Verify email address matches database exactly
- Check that Gmail App Password is correct
- Make sure 2-factor auth is enabled on Gmail

**"SMTP authentication error"**
- Double-check your Gmail App Password
- Make sure you're using an App Password, not your regular password
- Verify `MAIL_PORT` is set to `587`

## 💡 Next Steps

1. ✅ Install blastula package (already done!)
2. 📧 Configure email settings (follow "Quick Setup with Gmail" above)
3. 🧪 Test password reset locally
4. 🚀 Deploy to shinyapps.io with environment variables
5. 📢 Inform your team about the password reset feature!

---

**Need help?** Check `README_AUTH.md` for complete documentation.
