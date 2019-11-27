#!/bin/bash

echo "127.0.0.1 ${fqdn}" >> /etc/hosts
apt-get update
apt-get install mysql-client unzip apache2 apache2-utils -y

echo "MySQL DB provisioning.."
mysql -u${db_user} -h ${db_host} -p'${db_pass}' -e "CREATE DATABASE IF NOT EXISTS ${db_name};"

apt-get install php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-mysql -y
service apache2 restart

wget -c http://wordpress.org/latest.zip
unzip latest.zip

mkdir -p /var/www/html/
rsync -av wordpress/* /var/www/html/

cat > /var/www/html/wp-config.php <<EOL
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', '${db_name}' );
/** MySQL database username */
define( 'DB_USER', '${db_user}' );
/** MySQL database password */
define( 'DB_PASSWORD', '${db_pass}' );
/** MySQL hostname */
define( 'DB_HOST', '${db_host}' );
/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );
/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );
/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );
/**#@-*/
/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix = 'wp_';
/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define( 'WP_DEBUG', false );
/* That's all, stop editing! Happy publishing. */
/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}
/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
EOL

rm /var/www/html/index.html

cat > /etc/apache2/sites-available/000-default.conf <<EOL
<VirtualHost *:80>
	ServerAdmin admin@hostname.com
	ServerName  ${fqdn}
	ServerAlias www.${fqdn}
 
	# Indexes + Directory Root.
	DirectoryIndex index.php index.html
	DocumentRoot /var/www/html/
</VirtualHost>
EOL

chown -R www-data:www-data /var/www/html/
chmod -R 0640 /var/www/html/
chmod +X -R /var/www/html/
service apache2 restart
sleep 20
