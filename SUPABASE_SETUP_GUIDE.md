# Supabase Integration Setup Guide

This guide will help you set up the OLTrap Mapping app with Supabase for live database functionality.

## 🚀 Quick Setup

### 1. Create Supabase Project

1. **Go to your Supabase Dashboard**: https://supabase.com/dashboard/org/tlxvuhdckokgzqipsjpb
2. **Create a new project** (or use existing one)
3. **Project Settings** → **API** → Copy your **Project URL** and **anon key**

### 2. Set Up Database Schema

1. **Go to SQL Editor** in your Supabase project
2. **Copy and paste** the contents of `supabase_schema.sql`
3. **Run the SQL** to create the database tables and policies

### 3. Update App Configuration

1. **Open** `lib/services/supabase_service.dart`
2. **Replace the URL and anon key** with your actual credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',  // Replace with your project URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY',  // Replace with your anon key
  debug: false,
);
```

### 4. Build and Run

```bash
flutter pub get
flutter run
```

## 📋 Detailed Instructions

### Step 1: Supabase Project Setup

#### Creating a New Project
1. Log in to [Supabase Dashboard](https://supabase.com/dashboard)
2. Click **"New Project"**
3. Choose your organization: `tlxvuhdckokgzqipsjpb`
4. Enter project details:
   - **Project Name**: `OLTrap Mapping`
   - **Database Password**: Create a strong password
   - **Region**: Choose closest to your users
5. Click **"Create new project"**
6. Wait for project to be ready (2-3 minutes)

#### Getting API Keys
1. Go to **Project Settings** → **API**
2. Copy the **Project URL** (looks like: `https://xxxxx.supabase.co`)
3. Copy the **anon public key** (starts with `eyJhbGciOiJIUzI1NiIs...`)

### Step 2: Database Schema Setup

#### Running the Schema SQL
1. Navigate to **SQL Editor** in your Supabase project
2. Click **"New query"**
3. Copy the entire contents of `supabase_schema.sql` from your project
4. Paste into the SQL editor
5. Click **"Run"** or press `Ctrl/Cmd + Enter`

#### What the Schema Creates:
- **`oltraps` table**: Main table for trap data
- **Indexes**: For better query performance
- **RLS Policies**: Row Level Security for data protection
- **Statistics View**: For analytics and reporting
- **Triggers**: Automatic timestamp management

### Step 3: App Configuration

#### Updating Supabase Credentials
1. Open `lib/services/supabase_service.dart`
2. Find the `initialize()` method
3. Replace the placeholder values:

```dart
await Supabase.initialize(
  url: 'https://your-project-id.supabase.co',  // Your Project URL
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',  // Your Anon Key
  debug: false,
);
```

#### Environment Variables (Optional)
For better security, consider using environment variables:

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  debug: false,
);
```

### Step 4: Testing the Integration

#### Initial Test
1. Run the app: `flutter run`
2. Grant all permissions when prompted
3. Try scanning a QR code
4. Check if data appears in Supabase dashboard

#### Database Verification
1. Go to **Table Editor** in Supabase
2. Select the `oltraps` table
3. You should see your test data

## 🔧 Configuration Options

### Database URL Format
```
https://[project-id].supabase.co
```

### Anon Key Format
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iltwcm9qZWN0LWlkXSIsInJvbGUiOiJhbm9uIiwiaWF0IjpbdGltZXN0YW1wXSwiZXhwIjpbZXhwaXJ5XSwiYXVkIjoiaHR0cHM6Ly9bcHJvamVjdC1pZF0uc3VwYWJhc2UuY28ifQ.[signature]
```

### Security Settings

#### Row Level Security (RLS)
The schema includes RLS policies that:
- Allow all authenticated users to read data
- Allow all authenticated users to insert data
- Allow users to update their own records
- Allow users to delete their own records

#### Custom Policies (Optional)
You can modify the policies in the SQL schema to fit your specific needs:

```sql
-- Example: Restrict to specific users
CREATE POLICY "User-specific access" ON oltraps
    FOR ALL USING (auth.uid() = user_id);
```

## 🚀 Deployment

### Production Build
```bash
flutter build apk --release
```

### Environment Configuration
For production, consider:
1. Using environment variables for credentials
2. Enabling additional security policies
3. Setting up proper user authentication
4. Configuring database backups

### Performance Optimization
- **Indexes**: Already included in schema
- **Connection Pooling**: Managed by Supabase
- **Caching**: Consider implementing app-level caching
- **Pagination**: Implement for large datasets

## 🔍 Troubleshooting

### Common Issues

#### Connection Errors
**Error**: `Connection refused` or `Network error`
**Solution**: 
1. Verify Supabase URL is correct
2. Check internet connection
3. Ensure project is active

#### Authentication Errors
**Error**: `Invalid API key`
**Solution**:
1. Verify anon key is correct
2. Check if key is enabled
3. Ensure project is not paused

#### Permission Errors
**Error**: `Permission denied for table oltraps`
**Solution**:
1. Run the schema SQL completely
2. Check RLS policies
3. Verify user is authenticated

#### Data Not Appearing
**Problem**: Data saved in app but not in Supabase
**Solution**:
1. Check console for errors
2. Verify network connectivity
3. Check Supabase logs

### Debug Mode
Enable debug mode to see detailed logs:

```dart
await Supabase.initialize(
  url: 'your-url',
  anonKey: 'your-key',
  debug: true,  // Enable for debugging
);
```

### Console Logs
Monitor these logs:
- **Network requests**: Check API calls
- **Database operations**: Verify SQL queries
- **Authentication**: Check user status

## 📊 Monitoring

### Supabase Dashboard
Monitor your database usage:
1. **Project Settings** → **Database**
2. **Usage metrics**: Track queries and storage
3. **Logs**: View error logs and performance
4. **Backups**: Ensure data safety

### App Analytics
Consider implementing:
- **Error tracking**: Firebase Crashlytics
- **Usage analytics**: Firebase Analytics
- **Performance monitoring**: Custom metrics

## 🔐 Security Best Practices

### API Keys
- **Never expose** service role keys in client code
- **Use anon keys** for client applications
- **Rotate keys** periodically
- **Restrict key usage** by IP if needed

### Database Security
- **Enable RLS** on all tables
- **Use specific policies** for different user roles
- **Validate input data** before insertion
- **Implement rate limiting** if needed

### User Authentication
Consider implementing:
- **Email/password authentication**
- **Social login options**
- **Multi-factor authentication**
- **Session management**

## 📱 Migration from SQLite

### Data Migration
To migrate existing SQLite data to Supabase:

1. **Export** your current SQLite database
2. **Convert** data to Supabase format
3. **Import** using the app's import function
4. **Verify** all data is transferred correctly

### Backup Strategy
- **Keep SQLite backups** during transition
- **Test migration** with sample data first
- **Document** the migration process
- **Rollback plan** if issues occur

## 🆘 Support

### Getting Help
- **Supabase Documentation**: https://supabase.com/docs
- **Flutter Supabase Package**: https://pub.dev/packages/supabase_flutter
- **GitHub Issues**: Report bugs in the project repository

### Community Resources
- **Supabase Discord**: https://discord.gg/supabase
- **Flutter Community**: https://discord.gg/flutter
- **Stack Overflow**: Tag questions with `supabase` and `flutter`

## 📈 Next Steps

After successful setup:

1. **Test all features** thoroughly
2. **Implement user authentication** if needed
3. **Add real-time updates** using Supabase subscriptions
4. **Set up monitoring** and analytics
5. **Plan for scaling** as user base grows

---

**🎉 Congratulations!** Your OLTrap Mapping app now uses Supabase for live database functionality with real-time synchronization across all devices!
