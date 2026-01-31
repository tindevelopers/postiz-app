#!/bin/bash

# Postiz User Administration Script
# Usage: ./admin-users.sh [command]

DB_CONTAINER="postiz-postgres"
DB_USER="postiz-user"
DB_NAME="postiz-db-local"

case "$1" in
  list)
    echo "📋 All Users:"
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    SELECT 
      email, 
      CASE WHEN \"isSuperAdmin\" THEN 'Yes' ELSE 'No' END as \"Super Admin\",
      CASE WHEN activated THEN 'Active' ELSE 'Disabled' END as \"Status\",
      TO_CHAR(\"createdAt\", 'YYYY-MM-DD HH24:MI') as \"Created\",
      TO_CHAR(\"lastOnline\", 'YYYY-MM-DD HH24:MI') as \"Last Online\"
    FROM \"User\" 
    ORDER BY \"createdAt\" DESC;
    "
    ;;
    
  promote)
    if [ -z "$2" ]; then
      echo "❌ Error: Email required"
      echo "Usage: ./admin-users.sh promote user@example.com"
      exit 1
    fi
    echo "⬆️  Promoting $2 to Super Admin..."
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    UPDATE \"User\" 
    SET \"isSuperAdmin\" = true 
    WHERE email = '$2';
    "
    echo "✅ Done! User is now a Super Admin"
    ;;
    
  demote)
    if [ -z "$2" ]; then
      echo "❌ Error: Email required"
      echo "Usage: ./admin-users.sh demote user@example.com"
      exit 1
    fi
    echo "⬇️  Removing Super Admin from $2..."
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    UPDATE \"User\" 
    SET \"isSuperAdmin\" = false 
    WHERE email = '$2';
    "
    echo "✅ Done! User is no longer a Super Admin"
    ;;
    
  disable)
    if [ -z "$2" ]; then
      echo "❌ Error: Email required"
      echo "Usage: ./admin-users.sh disable user@example.com"
      exit 1
    fi
    echo "🔒 Disabling user $2..."
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    UPDATE \"User\" 
    SET activated = false 
    WHERE email = '$2';
    "
    echo "✅ Done! User account disabled"
    ;;
    
  enable)
    if [ -z "$2" ]; then
      echo "❌ Error: Email required"
      echo "Usage: ./admin-users.sh enable user@example.com"
      exit 1
    fi
    echo "🔓 Enabling user $2..."
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    UPDATE \"User\" 
    SET activated = true 
    WHERE email = '$2';
    "
    echo "✅ Done! User account enabled"
    ;;
    
  delete)
    if [ -z "$2" ]; then
      echo "❌ Error: Email required"
      echo "Usage: ./admin-users.sh delete user@example.com"
      exit 1
    fi
    echo "⚠️  WARNING: This will permanently delete the user and all their data!"
    echo "Press Ctrl+C to cancel, or Enter to continue..."
    read
    echo "🗑️  Deleting user $2..."
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    DELETE FROM \"User\" 
    WHERE email = '$2';
    "
    echo "✅ Done! User deleted"
    ;;
    
  count)
    echo "📊 User Statistics:"
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
    SELECT 
      COUNT(*) as \"Total Users\",
      SUM(CASE WHEN \"isSuperAdmin\" THEN 1 ELSE 0 END) as \"Super Admins\",
      SUM(CASE WHEN activated THEN 1 ELSE 0 END) as \"Active Users\",
      SUM(CASE WHEN NOT activated THEN 1 ELSE 0 END) as \"Disabled Users\"
    FROM \"User\";
    "
    ;;
    
  *)
    echo "Postiz User Administration"
    echo ""
    echo "Usage: ./admin-users.sh [command] [email]"
    echo ""
    echo "Commands:"
    echo "  list              - List all users"
    echo "  count             - Show user statistics"
    echo "  promote <email>   - Make user a Super Admin"
    echo "  demote <email>    - Remove Super Admin from user"
    echo "  enable <email>    - Enable user account"
    echo "  disable <email>   - Disable user account"
    echo "  delete <email>    - Delete user (WARNING: permanent!)"
    echo ""
    echo "Examples:"
    echo "  ./admin-users.sh list"
    echo "  ./admin-users.sh promote user@example.com"
    echo "  ./admin-users.sh disable user@example.com"
    ;;
esac
