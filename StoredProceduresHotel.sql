#Registrar una nueva reserva
DELIMITER //
CREATE PROCEDURE registrar_reserva(
    IN p_idHuesped INT,
    IN p_idHabitacion INT,
    IN p_fechaInicio DATE,
    IN p_fechaFin DATE,
    IN p_canal VARCHAR(50),
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE habitacion_disponible INT;
    

    SELECT COUNT(*) INTO habitacion_disponible
    FROM HABITACION
    WHERE idHabitacion = p_idHabitacion AND estado = 'DISPONIBLE';
    
    IF habitacion_disponible = 0 THEN
        SET p_resultado = 'Error: La habitación no está disponible';
    ELSEIF p_fechaFin <= p_fechaInicio THEN
        SET p_resultado = 'Error: La fecha de salida debe ser posterior a la fecha de entrada';
    ELSE
        -- Registrar la reserva
        INSERT INTO RESERVA (idHuesped, idHabitacion, fechaInicio, fechaFin, canal, estado)
        VALUES (p_idHuesped, p_idHabitacion, p_fechaInicio, p_fechaFin, p_canal, 'CONFIRMADA');
        
        -- Actualizar estado de la habitación
        UPDATE HABITACION SET estado = 'RESERVADA' WHERE idHabitacion = p_idHabitacion;
        
        SET p_resultado = CONCAT('Reserva registrada exitosamente con ID: ', LAST_INSERT_ID());
    END IF;
END //
DELIMITER ;

#Actualizar el estado de una habitacion: "Ocupado" o "Disponible"
DELIMITER //
CREATE PROCEDURE actualizar_estado_habitacion(
    IN p_idHabitacion INT,
    IN p_nuevoEstado VARCHAR(20),
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE existe_habitacion INT;
    

    SELECT COUNT(*) INTO existe_habitacion
    FROM HABITACION
    WHERE idHabitacion = p_idHabitacion;
    
    IF existe_habitacion = 0 THEN
        SET p_resultado = 'Error: La habitación no existe';
    ELSE

        UPDATE HABITACION
        SET estado = p_nuevoEstado
        WHERE idHabitacion = p_idHabitacion;
        
        SET p_resultado = CONCAT('Estado de la habitación ', p_idHabitacion, ' actualizado a: ', p_nuevoEstado);
    END IF;
END //
DELIMITER ;

#Para acelerar el check-out de los huespedes genera una factura rapida del cliente
DELIMITER //
CREATE PROCEDURE generar_factura_rapida(
    IN p_idReserva INT,
    OUT p_idFactura INT,
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE v_idHuesped INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_iva DECIMAL(12,2);
    DECLARE v_dias INT;
    DECLARE v_precio_noche DECIMAL(10,2);
    
    SELECT r.idHuesped, DATEDIFF(r.fechaFin, r.fechaInicio), h.precioNoche
    INTO v_idHuesped, v_dias, v_precio_noche
    FROM RESERVA r
    JOIN HABITACION h ON r.idHabitacion = h.idHabitacion
    WHERE r.idReserva = p_idReserva;

    SET v_subtotal = v_dias * v_precio_noche;
    SET v_iva = v_subtotal * 0.16; -- Suponiendo 16% de IVA
    SET v_total = v_subtotal + v_iva;

    INSERT INTO FACTURA (idReserva, idHuesped, fechaEmision, subtotal, iva, total, metodoPago, estado)
    VALUES (p_idReserva, v_idHuesped, NOW(), v_subtotal, v_iva, v_total, 'EFECTIVO', 'PAGADA');
    
    SET p_idFactura = LAST_INSERT_ID();
    SET p_resultado = CONCAT('Factura generada exitosamente con ID: ', p_idFactura);
END //
DELIMITER ;

#Verificacion de disponibilidad de habitaciones antes de la reservacion
DELIMITER //
CREATE PROCEDURE verificar_disponibilidad(
    IN p_fechaInicio DATE,
    IN p_fechaFin DATE,
    IN p_codigoCategoria VARCHAR(10)
)
BEGIN

    SELECT h.idHabitacion, h.numero, h.precioNoche, ch.descripcion AS categoria
    FROM HABITACION h
    JOIN CATEGORIA_HABITACION ch ON h.codigoCategoria = ch.codigo
    WHERE h.codigoCategoria = IFNULL(p_codigoCategoria, h.codigoCategoria)
    AND h.estado = 'DISPONIBLE'
    AND NOT EXISTS (
        SELECT 1 
        FROM RESERVA r
        WHERE r.idHabitacion = h.idHabitacion
        AND r.estado != 'CANCELADA'
        AND r.fechaInicio < p_fechaFin
        AND r.fechaFin > p_fechaInicio
    );
END //
DELIMITER ;

#Registro de servicios utilizados por un cliente
DELIMITER //
CREATE PROCEDURE registrar_servicio_cliente(
    IN p_idReserva INT,
    IN p_idServicio INT,
    IN p_cantidad INT,
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_reserva_valida INT;

    SELECT COUNT(*) INTO v_reserva_valida
    FROM RESERVA
    WHERE idReserva = p_idReserva AND estado = 'CONFIRMADA';
    
    IF v_reserva_valida = 0 THEN
        SET p_resultado = 'Error: Reserva no válida o cancelada';
    ELSE

        SELECT precio INTO v_precio
        FROM SERVICIO
        WHERE idServicio = p_idServicio;
 
        INSERT INTO CONSUMO_SERVICIO (idReserva, idServicio, fechaUso, horaUso)
        VALUES (p_idReserva, p_idServicio, CURDATE(), CURTIME());

        INSERT INTO DETALLE_FACTURA (idFactura, tipoItem, idItem, descripcion, cantidad, precioUnitario, importe)
        SELECT f.idFactura, 'SERVICIO', p_idServicio, s.nombre, p_cantidad, v_precio, (v_precio * p_cantidad)
        FROM FACTURA f
        JOIN SERVICIO s ON s.idServicio = p_idServicio
        WHERE f.idReserva = p_idReserva
        LIMIT 1;
        
        SET p_resultado = 'Servicio registrado exitosamente';
    END IF;
END //
DELIMITER ;

#Cancelar una reserva cuando el cliente cancela, y liberar la habitación o habitaciones reservadas.
DELIMITER //
CREATE PROCEDURE cancelar_reserva(
    IN p_idReserva INT,
    IN p_motivo VARCHAR(100),
    OUT p_resultado VARCHAR(100)
    )
BEGIN
    DECLARE v_idHabitacion INT;
    DECLARE v_estado_reserva VARCHAR(20);
    DECLARE v_dias_antes INT;
    DECLARE v_es_vip BOOLEAN;

    SELECT idHabitacion, estado, DATEDIFF(fechaInicio, CURDATE())
    INTO v_idHabitacion, v_estado_reserva, v_dias_antes
    FROM RESERVA
    WHERE idReserva = p_idReserva;

    SELECT esVIP INTO v_es_vip
    FROM CLIENTE_VIP
    WHERE idHuesped = (SELECT idHuesped FROM RESERVA WHERE idReserva = p_idReserva);
    
    IF v_estado_reserva = 'CANCELADA' THEN
        SET p_resultado = 'La reserva ya está cancelada';
    ELSE

        UPDATE RESERVA SET estado = 'CANCELADA' WHERE idReserva = p_idReserva;

        UPDATE HABITACION SET estado = 'DISPONIBLE' WHERE idHabitacion = v_idHabitacion;

        IF v_dias_antes < 2 AND NOT v_es_vip THEN

            CALL sp_generar_factura_penalizacion(p_idReserva, p_motivo, @factura_id);
            SET p_resultado = CONCAT('Reserva cancelada con penalización del 55%. Motivo: ', p_motivo);
        ELSE
            SET p_resultado = CONCAT('Reserva cancelada exitosamente. Motivo: ', p_motivo);
        END IF;
    END IF;
END //
DELIMITER ;

#Cuando el cliente sea VIP debe actualizar datos de cliente frecuente
DELIMITER //
CREATE PROCEDURE actualizar_cliente_vip(
    IN p_idHuesped INT)
BEGIN
    DECLARE v_total_reservas INT;

    SELECT COUNT(*) INTO v_total_reservas
    FROM RESERVA
    WHERE idHuesped = p_idHuesped AND estado = 'COMPLETADA';

    UPDATE CLIENTE_VIP
    SET contadorReservas = v_total_reservas,
        esVIP = CASE WHEN v_total_reservas >= 5 THEN TRUE ELSE FALSE END
    WHERE idHuesped = p_idHuesped;
    
    SELECT CONCAT('Cliente actualizado. Total reservas: ', v_total_reservas) AS resultado;
END //
DELIMITER ;

#Listar los clientes hospedados en tiempo real
DELIMITER //
CREATE PROCEDURE listar_clientes_hospedados()
BEGIN
    SELECT h.idHuesped, CONCAT(h.nombre, ' ', h.apellido) AS nombre_completo,
           hab.numero AS habitacion, r.fechaInicio, r.fechaFin
    FROM HUESPED h
    JOIN RESERVA r ON h.idHuesped = r.idHuesped
    JOIN HABITACION hab ON r.idHabitacion = hab.idHabitacion
    WHERE r.estado = 'CONFIRMADA'
    AND CURDATE() BETWEEN r.fechaInicio AND r.fechaFin
    AND EXISTS (
        SELECT 1 FROM CHECK_IN_OUT cio
        WHERE cio.idReserva = r.idReserva
        AND cio.tipo = 'IN'
    )
    AND NOT EXISTS (
        SELECT 1 FROM CHECK_IN_OUT cio
        WHERE cio.idReserva = r.idReserva
        AND cio.tipo = 'OUT'
    );
END //
DELIMITER ;

#Reporte de ingresos por mes
DELIMITER //
CREATE PROCEDURE reporte_ingresos_mensuales(
    IN p_anio INT)
BEGIN
    SELECT 
        MONTH(f.fechaEmision) AS mes,
        SUM(f.subtotal) AS subtotal,
        SUM(f.iva) AS iva,
        SUM(f.total) AS total,
        COUNT(*) AS facturas
    FROM FACTURA f
    WHERE YEAR(f.fechaEmision) = p_anio
    GROUP BY MONTH(f.fechaEmision)
    ORDER BY mes;
END //
DELIMITER ;

#Asignar upgrade de habitacion automatico a clientes VIP
DELIMITER //
CREATE PROCEDURE asignar_upgrade_vip(
    IN p_idReserva INT,
    OUT p_resultado VARCHAR(100))
BEGIN
    DECLARE v_idHuesped INT;
    DECLARE v_es_vip BOOLEAN;
    DECLARE v_categoria_actual VARCHAR(10);
    DECLARE v_idHabitacion_nueva INT;

    SELECT r.idHuesped, cv.esVIP, h.codigoCategoria
    INTO v_idHuesped, v_es_vip, v_categoria_actual
    FROM RESERVA r
    JOIN HABITACION h ON r.idHabitacion = h.idHabitacion
    LEFT JOIN CLIENTE_VIP cv ON r.idHuesped = cv.idHuesped
    WHERE r.idReserva = p_idReserva;
    
    IF v_es_vip = TRUE THEN
 
        SELECT hab.idHabitacion INTO v_idHabitacion_nueva
        FROM HABITACION hab
        JOIN CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
        WHERE hab.estado = 'DISPONIBLE'
        AND ch.codigo > v_categoria_actual
        ORDER BY ch.codigo DESC
        LIMIT 1;
        
        IF v_idHabitacion_nueva IS NOT NULL THEN

            UPDATE RESERVA
            SET idHabitacion = v_idHabitacion_nueva
            WHERE idReserva = p_idReserva;

            UPDATE HABITACION SET estado = 'DISPONIBLE' WHERE idHabitacion = (SELECT idHabitacion FROM RESERVA WHERE idReserva = p_idReserva);
            UPDATE HABITACION SET estado = 'RESERVADA' WHERE idHabitacion = v_idHabitacion_nueva;
            
            SET p_resultado = CONCAT('Upgrade aplicado. Nueva habitación: ', v_idHabitacion_nueva);
        ELSE
            SET p_resultado = 'No hay habitaciones disponibles para upgrade';
        END IF;
    ELSE
        SET p_resultado = 'El cliente no es VIP, no aplica upgrade';
    END IF;
END //
DELIMITER ;

