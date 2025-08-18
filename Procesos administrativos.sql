#Primer proceso administrativo
# Crear roles principales
CREATE ROLE rol_recepcion;
CREATE ROLE rol_finanzas;
CREATE ROLE rol_administrador;
CREATE ROLE rol_gerencia;

# Crear usuarios y asignar roles
CREATE USER 'recepcion_user'@'localhost' IDENTIFIED BY 'Recepcion123';
CREATE USER 'finanzas_user'@'localhost' IDENTIFIED BY 'Finanzas456';
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'Admin789';
CREATE USER 'gerente_user'@'%' IDENTIFIED BY 'Gerente012';

GRANT rol_recepcion TO 'recepcion_user'@'localhost';
GRANT rol_finanzas TO 'finanzas_user'@'localhost';
GRANT rol_administrador TO 'admin_user'@'localhost';
GRANT rol_gerencia TO 'gerente_user'@'%';

#Segundo proceso administrativo
#Privilegios para recepción
GRANT SELECT, INSERT, UPDATE ON hotel.RESERVA TO rol_recepcion;
GRANT SELECT, INSERT ON hotel.HUESPED TO rol_recepcion;
GRANT SELECT, INSERT ON hotel.CHECK_IN_OUT TO rol_recepcion;
GRANT SELECT ON hotel.HABITACION TO rol_recepcion;

#Privilegios para finanzas
GRANT SELECT, INSERT, UPDATE ON hotel.FACTURA TO rol_finanzas;
GRANT SELECT, INSERT ON hotel.DETALLE_FACTURA TO rol_finanzas;
GRANT SELECT ON hotel.RESERVA TO rol_finanzas;
GRANT SELECT ON hotel.SERVICIO TO rol_finanzas;

#Privilegios completos para administrador
GRANT ALL PRIVILEGES ON hotel.* TO rol_administrador WITH GRANT OPTION;

#Privilegios de solo lectura para gerencia
GRANT SELECT ON hotel.* TO rol_gerencia;

#Tercer proceso administrativo
# Revocar permiso de eliminación a recepción
REVOKE DELETE ON hotel.RESERVA FROM rol_recepcion;

# Revocar todos los permisos de un usuario
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'finanzas_user'@'localhost';

-- Respaldo completo (ejecutar en línea de comandos, no en cliente SQL)
-- mysqldump -u root -p --databases hotel > respaldo_completo.sql

-- Respaldo incremental (habilitar binlog primero)
SET GLOBAL log_bin = ON;
SET GLOBAL binlog_format = 'ROW';

-- Para recuperación:
-- mysql -u root -p hotel < respaldo_completo.sql
-- mysqlbinlog binlog.000001 | mysql -u root -p

#Tercer proceso administrativo

-- En el servidor maestro (ejecutar como root)
SET GLOBAL server_id = 1;
SET GLOBAL log_bin = ON;
SET GLOBAL binlog_format = ROW;
CREATE USER 'replicador'@'%' IDENTIFIED BY 'Replica123';
GRANT REPLICATION SLAVE ON *.* TO 'replicador'@'%';

-- En el servidor esclavo
CHANGE MASTER TO
MASTER_HOST='master_ip',
MASTER_USER='replicador',
MASTER_PASSWORD='Replica123',
MASTER_LOG_FILE='binlog.000001',
MASTER_LOG_POS=107;
START SLAVE;


#Cuarto proceso administrativo

-- Operación típica de recepción (check-in)
-- Ejecutado como 'recepcion_user'
INSERT INTO CHECK_IN_OUT (idReserva, idPersona, tipo, fecha, hora)
VALUES (101, 15, 'IN', CURDATE(), CURTIME());

-- Operación típica de finanzas (generar factura)
-- Ejecutado como 'finanzas_user'
CALL sp_generar_factura_rapida(101, @factura_id, @resultado);

-- Operación de administración (crear nuevo usuario)
-- Ejecutado como 'admin_user'
CREATE USER 'nuevo_recepcion'@'localhost' IDENTIFIED BY 'NuevoPass123';
GRANT rol_recepcion TO 'nuevo_recepcion'@'localhost';