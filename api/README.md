## Database Backup and Restore

### Resources

- https://www.pgadmin.org/docs/pgadmin4/9.2/backup_dialog.html
- https://www.pgadmin.org/docs/pgadmin4/9.2/restore_dialog.html
- https://www.postgresql.org/docs/17/app-pgdump.html

### Initialize the Connection to the Organize Production Server

You only need to do this once.

1. Install [pgAdmin 4](https://www.postgresql.org/ftp/pgadmin/pgadmin4/v9.2/macos/) on your dev machine
2. Open **pgAdmin 4**
3. Click **Add New Server** in the **Quick Links** section of the **Default Workspace** tab
4. Fill in the following info. Use the default values for any field not mentioned.
    - General tab
        - Name: Organize Production
    - Connection tab
        - Host name/address: localhost
        - Password: Copy/paste from password manager Organize production ORGANIZE_DATABASE_PASSWORD
        - Save password: true
    - SSH Tunnel tab
        - Use SSH tunneling: true
        - Tunnel host: org
        - Username: pi
        - Authentication: Identity file
        - Identity file: ~/.ssh/organize_server
5. Click **Save** to save and connect

### Connect to the Organize Production Server

1. Open **pgAdmin 4** on your dev machine
2. Click the **Servers** dropdown in the top left corner of the **Default Workspace** tab
3. When prompted for the **SSH Tunnel password for the identity file**, click **OK**

### Create a Backup

1. Connect to the **Organize Production** server in pgAdmin 4 (see above)
2. Right click **organize_production** under **Servers > Organize Production > Databases**
3. Click **Backup...**
4. Fill in the following info. Use the default values for any field not mentioned.
    - Filename: Desktop/apps/organize/backups/YYYY-MM-DD
5. Click **Backup**

### Restore a Backup

1. If needed, drop any existing database
    - Do NOT do this unless you are sure that you have a recent backup
    - Note that using db:reset in the command below will NOT work
    - `ssh org` then `docker compose restart db && docker compose exec -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 api bin/rails db:drop`
2. Connect to the **Organize Production** server in pgAdmin 4 (see above)
3. Right click **Databases** under **Servers > Organize Production**
4. Click **Create > Database...**
5. Fill in the following info. Use the default values for any field not mentioned.
    - Database: organize_production
6. Click **Save**
7. Right click **organize_production** under **Servers > Organize Production > Databases**
8. Click **Restore...**
9. Fill in the following info. Use the default values for any field not mentioned.
    - Filename: Desktop/apps/organize/backups/YYYY-MM-DD
10. Click **Restore**
