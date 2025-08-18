#CONSULTA 1
SELECT h.idHabitacion, h.numero, ch.descripcion AS tipo, h.precioNoche
FROM HABITACION h
JOIN CATEGORIA_HABITACION ch ON h.codigoCategoria = ch.codigo
WHERE h.estado = 'DISPONIBLE'
AND h.idHabitacion NOT IN (
    SELECT idHabitacion FROM RESERVA 
    WHERE CURDATE() BETWEEN fechaInicio AND fechaFin
    AND estado = 'CONFIRMADA'
);

#CONSULTA 2
SELECT 
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    r.fechaInicio,
    r.fechaFin,
    hab.codigoCategoria AS habitacion
FROM 
    HUESPED h
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
WHERE 
    r.estado = 'CONFIRMADA'
    AND NOT EXISTS (
        SELECT 1 FROM CHECK_IN_OUT cio 
        WHERE cio.idReserva = r.idReserva AND cio.tipo = 'IN'
    );
    
    #CONSULTA 3
    SELECT 
    ch.descripcion AS tipo_habitacion,
    COUNT(*) AS total_habitaciones,
    SUM(CASE WHEN r.idReserva IS NOT NULL THEN 1 ELSE 0 END) AS ocupadas,
    ROUND((SUM(CASE WHEN r.idReserva IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS porcentaje_ocupacion
FROM 
    HABITACION hab
JOIN 
    CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
LEFT JOIN 
    RESERVA r ON hab.idHabitacion = r.idHabitacion
    AND r.fechaInicio AND r.fechaFin BETWEEN '2023-05-16' AND '2023-07-21'
    AND r.estado = 'CONFIRMADA'
GROUP BY 
    ch.descripcion;
    
#CONSULTA 4
SELECT 
	ch.descripcion AS tipo_habitacion,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    r.fechaInicio,
    r.fechaFin,
    hab.numero AS habitacion
FROM 
    HUESPED h
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
WHERE 
    r.estado = 'CONFIRMADA'
    AND r.fechaInicio AND r.fechaFin BETWEEN '2023-05-16' AND '2023-07-21'
ORDER BY 
    tipo_habitacion;
    
#CONSULTA 5
SELECT 
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    r.fechaInicio,
    r.fechaFin,
    hab.numero AS habitacion,
    ch.descripcion AS tipo_habitacion
FROM 
    HUESPED h
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
WHERE 
    r.estado = 'CONFIRMADA'
    AND r.fechaInicio BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY 
    r.fechaInicio;
    
#CONSULTA 6
SELECT 
    r.idReserva,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    r.fechaInicio,
    r.fechaFin,
    hab.numero AS habitacion
FROM 
    RESERVA r
JOIN 
    HUESPED h ON r.idHuesped = h.idHuesped
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
WHERE 
    r.estado = 'cancelada'
    AND r.fechaInicio BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
ORDER BY 
    r.fechaInicio DESC;
    
    
#CONSULTA 7
SELECT 
    h.idHuesped,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    COUNT(r.idReserva) AS total_reservas,
    MAX(r.fechaInicio) AS ultima_reserva
FROM 
    HUESPED h
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
WHERE 
    r.estado = 'CONFIRMADA'
GROUP BY 
    h.idHuesped, h.nombre, h.apellido
HAVING 
    COUNT(h.idHuesped) >= 5
ORDER BY 
    total_reservas DESC;
    
#CONSULTA 8
SELECT 
    s.nombre AS servicio,
    s.tipo,
    COUNT(*) AS veces_utilizado,
    SUM(cs.cantidadDias) AS dias_consumo
FROM 
    SERVICIO s
JOIN 
    CONSUMO_SERVICIO cs ON s.idServicio = cs.idServicio
JOIN 
    RESERVA r ON cs.idReserva = r.idReserva
WHERE 
    cs.fechaUso BETWEEN '2023-05-16' AND '2023-07-21'
GROUP BY 
    s.idServicio, s.nombre, s.tipo
ORDER BY 
    veces_utilizado DESC;

#CONSULTA 9
SELECT 
    DATE(f.fechaEmision) AS fecha,
    SUM(f.subtotal) AS subtotal,
    SUM(f.iva) AS iva,
    SUM(f.total) AS total,
    COUNT(*) AS facturas
FROM 
    FACTURA f
WHERE 
    f.fechaEmision BETWEEN '2023-05-16' AND '2023-07-21'
    AND f.estado = 'PAGADA'
GROUP BY 
    DATE(f.fechaEmision)
ORDER BY 
    fecha;
    
#CONSULTA 10
SELECT 
    f.idFactura,
    f.fechaEmision,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    f.subtotal,
    f.iva,
    f.total,
    f.metodoPago
FROM 
    FACTURA f
JOIN 
    HUESPED h ON f.idHuesped = h.idHuesped
WHERE 
    f.fechaEmision BETWEEN '2023-05-01' AND '2023-11-30'
ORDER BY 
    f.fechaEmision DESC;


#CONSULTA 11
SELECT 
    h.idHuesped,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    COUNT(r.idReserva) AS total_reservas,
    SUM(DATEDIFF(r.fechaFin, r.fechaInicio)) AS noches_totales,
    SUM(f.total) AS gasto_total
FROM 
    HUESPED h
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
JOIN 
    FACTURA f ON r.idReserva = f.idReserva
WHERE 
    r.estado = 'CONFIRMADA'
    AND f.estado = 'PAGADA'
GROUP BY 
    h.idHuesped, h.nombre, h.apellido
ORDER BY 
    gasto_total DESC
LIMIT 10;

#CONSULTA 12
SELECT 
    h.idHabitacion,
    h.numero,
    ch.descripcion AS tipo_habitacion,
    h.estado
FROM 
    HABITACION h
JOIN 
    CATEGORIA_HABITACION ch ON h.codigoCategoria = ch.codigo
WHERE 
    h.idHabitacion NOT IN (
        SELECT DISTINCT r.idHabitacion
        FROM RESERVA r
        WHERE r.estado = 'COMPLETADA'
        AND r.fechaFin BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    )
ORDER BY 
    h.idHabitacion;
    
    
#CONSULTA 13
SELECT 
    ch.descripcion,
    AVG(DATEDIFF(r.fechaFin, r.fechaInicio)) AS duracion_promedio,
    COUNT(r.idReserva) AS total_reservas
FROM 
    RESERVA r
JOIN 
    HABITACION h ON r.idHabitacion = h.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON h.codigoCategoria = ch.codigo
WHERE 
    r.estado = 'CONFIRMADA'
    AND r.fechaInicio BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
GROUP BY 
    ch.descripcion
ORDER BY 
    duracion_promedio DESC;
    
    
#CONSULTA 14
SELECT 
    s.idServicio,
    s.nombre,
    s.tipo,
    s.precio
FROM 
    SERVICIO s
WHERE 
    s.idServicio NOT IN (
        SELECT DISTINCT cs.idServicio
        FROM CONSUMO_SERVICIO cs
        WHERE cs.fechaUso BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    )
ORDER BY 
    s.idServicio;
    

#CONSULTA 15
SELECT 
    ch.descripcion AS tipo_habitacion,
    COUNT(*) AS total_reservas
FROM 
    RESERVA r
JOIN 
    HABITACION h ON r.idHabitacion = h.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON h.codigoCategoria = ch.codigo
WHERE 
    r.estado = 'CONFIRMADA'
    AND r.fechaInicio BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
GROUP BY 
    ch.descripcion
ORDER BY 
	total_reservas DESC;
    


#CONSULTA 17
SELECT 
    h.lugarProcedencia AS pais_origen,
    COUNT(*) AS total_reservas,
    SUM(DATEDIFF(r.fechaFin, r.fechaInicio)) AS noches_totales,
    SUM(f.total) AS ingresos_totales
FROM 
    HUESPED h
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
JOIN 
    FACTURA f ON r.idReserva = f.idReserva
WHERE 
    r.estado = 'CONFIRMADA'
    AND r.fechaInicio BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
GROUP BY 
    h.lugarProcedencia
ORDER BY 
    total_reservas DESC;
    
#CONSULTA 18
SELECT 
    DATE(f.fechaEmision) AS fecha,
    AVG(f.total) AS promedio_diario,
    COUNT(*) AS facturas_dia,
    SUM(f.total) AS total_dia
FROM 
    FACTURA f
WHERE 
    f.fechaEmision BETWEEN '2023-01-15' AND '2023-01-16' 
    AND f.estado = 'PAGADA'
GROUP BY 
    DATE(f.fechaEmision)
ORDER BY 
    fecha;
    
#CONSULTA 19
SELECT 
    idHuesped,
    CONCAT(nombre, ' ', apellido) AS cliente,
    telefonoCelular,
    lugarProcedencia
FROM 
    HUESPED
WHERE 
    email IS NULL OR email = ''
ORDER BY 
    apellido, nombre;
    
#CONSULTA 20
SELECT 
    h.idHuesped,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    cv.contadorReservas,
    r.idReserva,
    hab.numero AS habitacion,
    ch.descripcion AS tipo_habitacion,
    r.fechaInicio,
    r.fechaFin
FROM 
    HUESPED h
JOIN 
    CLIENTE_VIP cv ON h.idHuesped = cv.idHuesped
JOIN 
    RESERVA r ON h.idHuesped = r.idHuesped
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
WHERE 
    cv.esVIP = TRUE
    AND r.estado = 'CONFIRMADA'
    AND CURDATE() BETWEEN r.fechaInicio AND r.fechaFin
    AND EXISTS (
        SELECT 1 FROM CHECK_IN_OUT cio 
        WHERE cio.idReserva = r.idReserva AND cio.tipo = 'CHECK-IN'
    )
ORDER BY 
    cv.contadorReservas DESC;

#CONSULTA 21
SELECT 
    h.idHabitacion,
    h.numero AS numero_habitacion,
    beh.fechaCambio,
    beh.estadoAnterior,
    beh.estadoNuevo,
    CONCAT(hu.nombre, ' ', hu.apellido) AS cliente,
    r.idReserva,
    r.fechaInicio,
    r.fechaFin,
    f.total AS costo,
    e.nombre AS agente_mostrador
FROM 
    BITACORA_ESTADO_HABITACION beh
JOIN 
    HABITACION h ON beh.idHabitacion = h.idHabitacion
LEFT JOIN 
    RESERVA r ON h.idHabitacion = r.idHabitacion 
    AND beh.fechaCambio BETWEEN r.fechaInicio AND r.fechaFin
LEFT JOIN 
    HUESPED hu ON r.idHuesped = hu.idHuesped
LEFT JOIN 
    FACTURA f ON r.idReserva = f.idReserva
LEFT JOIN 
    CHECK_IN_OUT cio ON r.idReserva = cio.idReserva AND cio.tipo = 'CHECK-IN'
LEFT JOIN 
    EMPLEADO e ON cio.idPersona = e.idEmpleado
ORDER BY 
    beh.fechaCambio DESC;
    
#CONSULTA 22
SELECT 
    f.idFactura,
    f.fechaEmision,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    f.subtotal,
    f.iva,
    f.total,
    f.metodoPago,
    DATEDIFF(CURDATE(), f.fechaEmision) AS dias_pendientes
FROM 
    FACTURA f
JOIN 
    HUESPED h ON f.idHuesped = h.idHuesped
WHERE 
    f.estado = 'PENDIENTE'
    AND f.fechaEmision BETWEEN '2023-01-01' AND '2025-11-30' 
ORDER BY 
    dias_pendientes DESC;
    
#CONSULTA 23
SELECT 
    r.idReserva,
    CONCAT(h.nombre, ' ', h.apellido) AS cliente,
    hab.numero AS habitacion,
    r.fechaInicio,
    r.fechaFin,
    DATEDIFF(CURDATE(), r.fechaFin) AS dias_expirada,
    r.estado
FROM 
    RESERVA r
JOIN 
    HUESPED h ON r.idHuesped = h.idHuesped
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
WHERE 
    r.fechaFin < CURDATE()
    AND r.estado NOT IN ('COMPLETADA', 'CANCELADA')
ORDER BY 
    dias_expirada DESC;
    
#CONSULTA 24
SELECT 
    ch.descripcion AS tipo_habitacion,
    COUNT(DISTINCT hab.idHabitacion) AS total_habitaciones,
    COUNT(DISTINCT CASE WHEN r.idReserva IS NOT NULL THEN hab.idHabitacion END) AS habitaciones_ocupadas,
    ROUND((COUNT(DISTINCT CASE WHEN r.idReserva IS NOT NULL THEN hab.idHabitacion END) / 
          COUNT(DISTINCT hab.idHabitacion)) * 100, 2) AS porcentaje_ocupacion,
    MONTH(r.fechaInicio) AS mes,
    YEAR(r.fechaInicio) AS año
FROM 
    CATEGORIA_HABITACION ch
JOIN 
    HABITACION hab ON ch.codigo = hab.codigoCategoria
LEFT JOIN 
    RESERVA r ON hab.idHabitacion = r.idHabitacion
    AND r.estado != 'CANCELADA'
    AND r.fechaInicio BETWEEN '2023-01-01' AND '2023-12-31'  
GROUP BY 
    ch.descripcion, MONTH(r.fechaInicio), YEAR(r.fechaInicio)
ORDER BY 
    año, mes, porcentaje_ocupacion DESC;
    
#CONSULTA 25
SELECT 
    ch.descripcion AS tipo_habitacion,
    SUM(DATEDIFF(r.fechaFin, r.fechaInicio) * hab.precioNoche) AS ingresos_habitacion,
    SUM(f.total) AS ingresos_totales,
    COUNT(r.idReserva) AS reservas
FROM 
    RESERVA r
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
JOIN 
    FACTURA f ON r.idReserva = f.idReserva
WHERE 
    r.fechaInicio BETWEEN '2023-01-01' AND '2025-11-30' 
    AND r.estado = 'CONFIRMADA'
GROUP BY 
    ch.descripcion
ORDER BY 
    ingresos_totales DESC;

#CONSULTA 26
SELECT 
    e.idEmpleado,
    e.nombre,
    e.puesto,
    COUNT(cio.idCheck) AS check_ins_realizados,
    COUNT(cio.idCheck) * 50 AS bono_acumulado  
FROM 
    EMPLEADO e
JOIN 
    CHECK_IN_OUT cio ON e.idEmpleado = cio.idPersona
WHERE 
    cio.tipo = 'CHECK-IN'
    AND cio.fecha BETWEEN '2023-01-01' AND '2023-11-30' 
GROUP BY 
    e.idEmpleado, e.nombre, e.puesto
ORDER BY 
    bono_acumulado DESC;
    
#CONSULTA 27
SELECT
    s.nombre AS servicio,
    s.tipo,
    COUNT(*) AS veces_utilizado,
    SUM(cs.cantidadDias) AS dias_consumo,
    COUNT(DISTINCT cv.idHuesped) AS clientes_vip
FROM 
    SERVICIO s
JOIN 
    CONSUMO_SERVICIO cs ON s.idServicio = cs.idServicio
JOIN 
    RESERVA r ON cs.idReserva = r.idReserva
JOIN 
    CLIENTE_VIP cv ON r.idHuesped = cv.idHuesped
WHERE 
    cs.fechaUso BETWEEN '2023-01-01' AND '2025-11-30'  
    AND cv.esVIP = TRUE
GROUP BY
    s.idServicio, s.nombre, s.tipo
ORDER BY 
    veces_utilizado DESC
LIMIT 10;

#CONSULTA 28
SELECT 
    CASE 
        WHEN q.descripcion LIKE '%limpieza%' THEN 'Limpieza'
        WHEN q.descripcion LIKE '%servicio%' THEN 'Servicio al Cliente'
        WHEN q.descripcion LIKE '%habitacion%' THEN 'Habitaciones'
        WHEN q.descripcion LIKE '%comida%' THEN 'Restaurante'
        ELSE 'Otros'
    END AS departamento,
    COUNT(*) AS total_quejas,
    GROUP_CONCAT(DISTINCT q.descripcion SEPARATOR ', ') AS quejas_ejemplo
FROM 
    QUEJA q
WHERE 
    q.fecha BETWEEN '2023-01-01' AND '2023-11-30'  
GROUP BY 
    departamento
ORDER BY 
    total_quejas DESC;
    
#CONSULTA 29
SELECT 
    CASE 
        WHEN s.tipo = 'LIMPIEZA' THEN 'LIMPIEZA'
        WHEN s.tipo = 'RESTAURANTE' THEN 'RESTAURANTE'
        WHEN s.tipo = 'SPA' THEN 'SPA'
        WHEN s.tipo = 'TRANSPORTE' THEN 'TRANSPORTE'
        ELSE 'Otros'
    END AS departamento,
    AVG(sat.calificacion) AS promedio_calificacion,
    COUNT(*) AS evaluaciones
FROM 
    SATISFACCION sat
JOIN 
    SERVICIO s ON sat.idServicio = s.idServicio
WHERE 
    sat.calificacion IS NOT NULL
    AND sat.idReserva IN (
        SELECT idReserva FROM RESERVA 
        WHERE fechaInicio BETWEEN '2023-01-01' AND '2023-11-30' 
    )
GROUP BY 
    departamento
ORDER BY 
    promedio_calificacion DESC
LIMIT 1;

#CONSULTA 30
SELECT 
    hab.numero AS habitacion,
    ch.descripcion AS tipo_habitacion,
    CONCAT(hu.nombre, ' ', hu.apellido) AS cliente,
    DATEDIFF(r.fechaFin, r.fechaInicio) AS duracion_estancia,
    r.fechaInicio,
    r.fechaFin,
    f.total AS costo_total
FROM 
    RESERVA r
JOIN 
    HABITACION hab ON r.idHabitacion = hab.idHabitacion
JOIN 
    CATEGORIA_HABITACION ch ON hab.codigoCategoria = ch.codigo
JOIN 
    HUESPED hu ON r.idHuesped = hu.idHuesped
JOIN 
    FACTURA f ON r.idReserva = f.idReserva
WHERE 
    r.fechaInicio BETWEEN '2023-01-01' AND '2023-11-30'  
    AND r.estado = 'CONFIRMADA'
ORDER BY 
    duracion_estancia DESC;