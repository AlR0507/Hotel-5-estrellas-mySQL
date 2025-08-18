#Cuando un cliente realiza un check-in, automaticamente la habitacion cambia de estado "ocupado"
DELIMITER //
CREATE TRIGGER check_in_automatico
AFTER INSERT ON CHECK_IN_OUT
FOR EACH ROW
BEGIN
    IF NEW.tipo = 'CHECK-IN' THEN
        UPDATE HABITACION h
        JOIN RESERVA r ON h.idHabitacion = r.idHabitacion
        SET h.estado = 'OCUPADO'
        WHERE r.idReserva = NEW.idReserva;
    END IF;
END //
DELIMITER ;

#Al terminar la estancia, liberar automaticamente la habitacion.
DELIMITER //
CREATE TRIGGER liberar_habitacion_automaticamente
AFTER INSERT ON CHECK_IN_OUT
FOR EACH ROW
BEGIN
    IF NEW.tipo = 'CHECK-OUT' THEN
        UPDATE HABITACION h
        JOIN RESERVA r ON h.idHabitacion = r.idHabitacion
        SET h.estado = 'DISPONIBLE'
        WHERE r.idReserva = NEW.idReserva;
    END IF;
END //
DELIMITER ;

#Llevar una bitacora de cada vez que cambie de estado una habitacion
DELIMITER //
CREATE TRIGGER bitacora_habitacion
AFTER UPDATE ON HABITACION
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado THEN
        INSERT INTO BITACORA_ESTADO_HABITACION (idHabitacion, fechaCambio, estadoAnterior, estadoNuevo)
        VALUES (NEW.idHabitacion, NOW(), OLD.estado, NEW.estado);
    END IF;
END //
DELIMITER ;

#Cada vez que un cliente se registre, agregarlo a la tabla de clienets potencialmente VIP
DELIMITER //
CREATE TRIGGER registro_cliente_vip
AFTER INSERT ON HUESPED
FOR EACH ROW
BEGIN
    INSERT INTO CLIENTE_VIP (idHuesped, fechaRegistro)
    VALUES (NEW.idHuesped, CURDATE());
END //
DELIMITER ;

#Cada vez que un cliente VIP hace una reserva debe actualizar su contador personal.
DELIMITER //
CREATE TRIGGER contador_vip
AFTER INSERT ON RESERVA
FOR EACH ROW
BEGIN
    UPDATE CLIENTE_VIP
    SET contadorReservas = contadorReservas + 1
    WHERE idHuesped = NEW.idHuesped;
    
    -- Si tiene 5 o más reservas, se convierte en VIP
    UPDATE CLIENTE_VIP
    SET esVIP = TRUE
    WHERE idHuesped = NEW.idHuesped AND contadorReservas >= 5;
END //
DELIMITER ;

#Validación para evitar que la fecha de salida sea mayor a la fecha de entrada, evitando así reservas invalidas.
DELIMITER //
CREATE TRIGGER validar_fechas
BEFORE INSERT ON RESERVA
FOR EACH ROW
BEGIN
    IF NEW.fechaFin <= NEW.fechaInicio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de salida debe ser posterior a la fecha de entrada';
    END IF;
END //
DELIMITER ;

#Control automático del inventario de habitaciones.
DELIMITER //
CREATE TRIGGER control_inventario
AFTER INSERT ON RESERVA
FOR EACH ROW
BEGIN
    #Insertar en CONTROL_FECHAS para cada día de la reserva
    DECLARE fecha_actual DATE;
    SET fecha_actual = NEW.fechaInicio;
    
    WHILE fecha_actual <= NEW.fechaFin DO
        INSERT INTO CONTROL_FECHAS (idHabitacion, fecha, estado)
        VALUES (NEW.idHabitacion, fecha_actual, 'RESERVADO')
        ON DUPLICATE KEY UPDATE estado = 'RESERVADO';
        
        SET fecha_actual = DATE_ADD(fecha_actual, INTERVAL 1 DAY);
    END WHILE;
END //
DELIMITER ;

#Si la fecha de entrada pasa y no se hizo el check-in, cancelar reserva de forma automática.
DELIMITER //
CREATE TRIGGER cancelar_reserva_sin_checkin
AFTER UPDATE ON RESERVA
FOR EACH ROW
BEGIN
    DECLARE existe_checkin INT;
    
    #Verificar si la fecha de inicio ya paso y no hay check-in
    IF NEW.estado = 'CONFIRMADA' AND NEW.fechaInicio < CURDATE() THEN
        SELECT COUNT(*) INTO existe_checkin FROM CHECK_IN_OUT 
        WHERE idReserva = NEW.idReserva AND tipo = 'IN';
        
        IF existe_checkin = 0 THEN
            UPDATE RESERVA 
            SET estado = 'CANCELADA'
            WHERE idReserva = NEW.idReserva;
            
            UPDATE HABITACION
            SET estado = 'DISPONIBLE'
            WHERE idHabitacion = NEW.idHabitacion;
        END IF;
    END IF;
END //
DELIMITER ;

#Evitar servicios registrados con precios negativos o cero.
DELIMITER //
CREATE TRIGGER validar_precio_servicio
BEFORE INSERT ON SERVICIO
FOR EACH ROW
BEGIN
    IF NEW.precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio del servicio debe ser mayor que cero';
    END IF;
END //
DELIMITER ;

#Cancelación de una reserva ya emitida por petición del cliente dentro del rango de fecha
DELIMITER //
CREATE TRIGGER cancelacion_reserva
BEFORE UPDATE ON RESERVA
FOR EACH ROW
BEGIN
    DECLARE dias_antes INT;
    DECLARE costo_reserva DECIMAL(12,2);
    
    IF NEW.estado = 'CANCELADA' AND OLD.estado != 'CANCELADA' THEN
        #Calcular dias antes de la fecha de inicio
        SET dias_antes = DATEDIFF(OLD.fechaInicio, CURDATE());
        
        #Calcular costo total de la reserva
        SELECT DATEDIFF(OLD.fechaFin, OLD.fechaInicio) * h.precioNoche INTO costo_reserva
        FROM HABITACION h
        WHERE h.idHabitacion = OLD.idHabitacion;
        
        #Si es cancelacion fuera del rango permitido (menos de 2 dias antes)
        IF dias_antes < 2 THEN
            #Crear factura con penalizacion del 55%
            INSERT INTO FACTURA (idReserva, idHuesped, fechaEmision, subtotal, iva, total, metodoPago, estado, detalles)
            VALUES (OLD.idReserva, OLD.idHuesped, NOW(), costo_reserva * 0.55, costo_reserva * 0.55 * 0.16, 
                   costo_reserva * 0.55 * 1.16, 'PENALIZACION', 'PAGADA', 'Penalización por cancelación tardía');
        END IF;
    END IF;
END //
DELIMITER ;