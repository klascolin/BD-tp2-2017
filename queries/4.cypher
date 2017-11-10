MATCH (u1:Usuario)-->(u2:Usuario)
WITH u1, count(u2) as salida
SET u1.cantNodosSalida = salida
RETURN u1.cantNodosSalida, count(u1)

MATCH (u1:Usuario)-->(u2:Usuario)
WITH u2, count(u1) as entrada
SET u2.cantNodosEntrada = entrada
RETURN u2.cantNodosEntrada, count(u2)