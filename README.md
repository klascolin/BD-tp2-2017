# Impacto de noticias falsas en redes sociales

**Base de datos:** NoSql Graph oriented

**Tecnología:** [Neo4j](https://neo4j.com)

## Introducción (summary)

 En este trabajo practico abordamos la tematica del impacto de las noticias falsas en las redes sociales. Dada una muestra de datos (tomada de [hoaxy](http://hoaxy.iuni.iu.edu)) buscamos respondernos una serie de preguntas utilizando una bate de datos orientada a grafos.
 
## Desarrollo

**Conversión de datos .json a .csv**
 Nuesto primer paso es convertir los datos que provienen en formato [json](http://www.json.org) a un formato aceptado por la base de datos ([csv](https://en.wikipedia.org/wiki/Comma-separated_values)). Para esto utilizamos [jq](https://stedolan.github.io/jq/):
```
jq -r '.edges[] | [.canonical_url, .date_published, .domain, .from_user_id, .from_user_screen_name, .id,.is_mention, .site_type,.title, .to_user_id, .to_user_screen_name, .tweet_created_at, .tweet_id, .tweet_type, .url_id | tostring]  | @csv ' noticias.json
```
 Con la instrucción anterior vamos a obtener un archivo llamado noticias.csv el cual debemos importar en la siguiente sección.
 
**Importar proyecto**
 
 El primer paso aquí es colocar el archivo noticias.csv en la carpera llamada "import" de node4j (esto requiere que esté [instalado localemente](https://neo4j.com/docs/operations-manual/current/installation/)). Luego ejecutar:
 
 
###### Cargar noticias

1. Creamos los nodos "Noticia" con los atributos url, idNoticia y titulo.
```
LOAD CSV FROM "file:///noticias.csv" AS line
MERGE (n:Noticia{url:line[0],idNoticia:line[5],titulo:line[8]});
```

2. Creamos los nodos "Usuario" con screenName y userId. Estos son los usuarios que crearon noticias
```
LOAD CSV FROM "file:///noticias.csv" AS line
MERGE (n:Usuario{screenName:line[4],userId:line[3]});
```

2. Creamos los nodos "Usuario" con screenName y userId. Estos son los usuarios que recibieron noticias. (no se deberían crear repetidos)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MERGE (n:Usuario{screenName:line[10],userId:line[9]});
```

3. Creamos las relaciones entre noticias y sus creadores (transición IMPACTA)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MATCH (n:Noticia {titulo: line[8]})
MATCH (u:Usuario {userId:line[3]})
MERGE (n)-[:IMPACTA]->(u);
```

4. Creamos las relaciones entre usuarios y las noticias que leyeron (transición IMPACTA)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MATCH (n:Noticia {titulo: line[8]})
MATCH (u:Usuario {userId:line[9]})
MERGE (n)-[:IMPACTA]->(u);
```

![Alt text](/img/graphImpacta_0.png?raw=true)

###### Agregar la relacion de infeccíon

5. Creamos las relaciones entre usuarios que se envian noticias (transición INFECTA)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MATCH (u1:Usuario {userId:line[3]})
MATCH (u2:Usuario {userId:line[9]})
MERGE (u1)-[:INFECTA]->(u2);
```
![Alt text](/img/graphInfecta_0.png?raw=true)

## Analisís

 A continuación responderemos una serie de consultas formuladas para entender mejor el dominio del problema.
 
1. Enumere las noticias que han impactado en más del 25 % de la comunidad.

Contamos los usuarios totales y pasamos el resultado a las siguientes clausulas
```
match (u:Usuario)
with count(u) as userNodes
```
Para una noticia, buscamos todos los usuarios a los que IMPACTA y contamos la cantidad de ejes salientes.
```
match (n:Noticia)-[r]-()
with userNodes, n, count(r) as degree 
```
Filtramos las noticias que tengan grado de impacto superior al 25% de la cantidad de usuarios totales y devolvemos el resultado

```
where degree > userNodes*0.25
return n.titulo AS node, degree
order by degree;
```
Al ejecutar dicha query en la base de datos, se obtuvo el siguiente resultado:

![Alt text](/img/tableQuery1.png?raw=true)

2. Genere el sub-grafo de usuarios que consumen las mismas noticias.

```
MATCH (n:Noticia)-[:IMPACTA]->(u:Usuario)
RETURN n as Noticia, collect(u) as Usuarios, count(u) as CantUsuarios
```
A continuacin se muestran los subgrafos correspondientes a tres noticias de la base

![Alt text](/img/graphQuery2.png?raw=true)

3. ¿Existen usuarios de Twitter que han estado en contacto con más del 20 % del lote de noticias?

Para cada usuario, buscamos todas las noticias que lo IMPACTAN (es decir, noticias que están en contacto con el mismo) y contamos el grado de entrada de dichos ejes
```
match(u:Usuario)
match( (n2:Noticia)-[r]->(u) )
with u, count(r) as inDegree
```
Contamos la cantidad total de noticias que hay en la base
```
match (n1:Noticia) 
with u, inDegree, count(n1) as news
```
Filtramos los usuarios obtenidos que tengan un grado de entrada mayor al 20% de la cantidad de noticias
```
where inDegree >= 0.2*news
return u.userId as Node, inDegree
```
![Alt text](/img/tableQuery3.png?raw=true)

4. ¿Cómo es la distribución de los grados de entrada y salida de los nodos? Presente la información en un histograma.

Agregamos grado de salida de nodos como etiquetas:
```
MATCH (u1:Usuario)-->(u2:Usuario)
WITH u1, count(u2) as salida
SET u1.cantNodosSalida = salida
```
Agregamos grado de entrada de nodos como etiquetas:
```
MATCH (u1:Usuario)-->(u2:Usuario)
WITH u2, count(u1) as entrada
SET u2.cantNodosEntrada = entrada
```
Agrupamos nodos por cardinalidad de salida:
```
MATCH (u1:Usuario)
RETURN u1.cantNodosSalida, count(u1)
```
Agrupamos nodos por cardinalidad de entrada:
```
MATCH (u1:Usuario)
RETURN u1.cantNodosEntrada, count(u1)
```
Notar que cuando cantNodos de entrada o salida da null es para el caso que no tiene nodos de entrada o salida (i.e cero).

![Alt text](/img/graphHistorigrama.png?raw=true)

![Alt text](/img/graphHistorigramaSin0.png?raw=true)

Podemos observar en los graficos que muestran los grados de salida, que la mayoría de la comunidad mantiene una actitud "pasiva" con respecto a la emisión de noticias y que, efectivamente, son pocos nodos de usuarios los que aportan un gran caudal de noticias. Por ejemplo, se observa que hay menos de diez nodos cuyo grado de infección (cantidad de noticias falsas difundidas) es superior a 100.
Por otra parte, se desprende del gráfico de grados de entrada, que aproximadamente el 65% de la comunidad fue penetetrada por 2 o menos noticias falsas.

5. Llamaremos root-influencers a los nodos raíces del grafo de infección. Escriba una consulta que dado un nodo de usuario en el grafo de infección diga si es root-influencer o no. ¿Qué proporción hay de root-influencers? Muestre la información apropiadamente.

Buscamos un nodo cuyo screenName sea "beforeitsnews"
```
MATCH (root:Usuario {screenName: "beforeitsnews"})-[:INFECTA]->()
```
Verificamos que no exista el siguiente patron. Es decir, que no haya nodos que lo infecten

```
WHERE NOT ()-[:INFECTA]->(root) 
```
Como es un nodo raiz, debe infectar al menos a otro usuario y entonces hubo al menos un patrón que "hizo match"

```
RETURN count(root) > 0 as esRoot
```
Para responder la siguiente pregunta, sobre la proporcin, realizamos la siguiente consulta:

Contamos la cantidad de usuarios totales 
```
MATCH (user:Usuario)
WITH count(distinct(user)) as total
```
Como se hizo antes, buscamos los nodos root , los que no son infectados por otros, y vemos la proporción entre ambas magnitudes obtenidas.
```
MATCH (root:Usuario)-[:INFECTA]->()
WHERE NOT ()-[:INFECTA]->(root) 
RETURN count(distinct(root))*100/total as proporcion
```
El resultado muestra la proporción expresada como un porcentaje:

![Alt text](/img/resultQuery5.png?raw=true)



6. Calcule el grado de la infección para un root-influencer dado. El grado de infección está dado por el camino más largo que se puede alcanzar desde un root-influencer.

Buscamos todos los caminos con relación de infección cuyo primer nodo tenga como screenName "LillyMunster3" y lo guardamos en la variable p.
```
MATCH p = (root:Usuario {screenName: "LillyMunster3"})-[:INFECTA*1..]->(m)
```

Retornamos todos los caminos y guardamos su longitud en la variable L.
```
RETURN p, length(p) as L
```

Ordenamos según su longitud y nos quedamos con el mas grande.
```
ORDER BY L DESC
LIMIT 1
```

El camino mas largo es, en este caso, de longitud 6.

![Alt text](/img/resultQuery6.png?raw=true)

7. Pode el grafo quitando todos los root-influencers y muestre gráficamente como queda el grafo resultante. Si la información es muy grande, recorte apropiadamente.

Buscamos los nodos que son root, como se hizo anteriormente, y los ordenamos en una lista de rooters. Pasamos dicha información a la siguiente parte de la query
```
MATCH (root:Usuario)-[:INFECTA]->()
WHERE NOT ()-[:INFECTA]->(root)
WITH collect( distinct(root)) as rooters

```
Buscamos todos los nodos usuarios que no esten en la lista de rooters y los devolvemos
```
MATCH (user:Usuario)
WHERE NOT user IN rooters
RETURN user;
```
A continuación se muestran parte de de dos componentes conexas del grafo, con los infectados por los root-influencer "The Onion" y "Ifollowstuff" antes y después de ejecutar la query. Notar que los nodos "null" en realidad se corresponden con idUsuarios distintos, pero con igual screenName. 

![Alt text](/img/graphQuery7_2.png?raw=true)

 
![Alt text](/img/graphQuery7_1.png?raw=true)


8. Considere la introducción de índices a los modelos. Evalué la performance de las consultas implementadas con y sin utilización de índices.

### query

1)
```
match (u:Usuario)
with count(u) as userNodes
match (n:Noticia)-[r]-()
with userNodes, n, count(r) as degree
where degree > userNodes*0.25
return n.titulo AS node, degree
order by degree;
```
Result:
Sin Indice:

 - Promedio: 2,6 
 - Varianza: 0.44

Con Indice "CREATE INDEX ON :Noticia(degrees)":
CREATE INDEX ON :Usuario(count)

 - Promedio: 2,2
 - Varianza: 0,16

2)
```
MATCH (n:Noticia)-[:IMPACTA]->(u:Usuario)
RETURN n as Noticia, collect(u) as Usuarios, count(u) as CantUsuarios
```
Result:
Sin Indice:

 - Promedio: 8,4
 - Varianza: 3,04

Con Indice "CREATE INDEX ON :Usuario(idNoticia)":

 - Promedio: 2,7
 - Varianza: 3,2


3)
```
match(u:Usuario)
match( (n2:Noticia)-[r]->(u) )
with u, count(r) as inDegree
match (n1:Noticia)
with u, inDegree, count(n1) as news
where inDegree >= 0.2*news
return u.userId as Node, inDegree
```
Result:
Sin Indice:

 - Promedio: 54,10
 - Varianza: 75,41

Con Indice "CREATE INDEX ON :Usuario(idNoticia)":

 - Promedio: Da decreciente
 - Varianza: 

4) 
```
MATCH (u1:Usuario)-->(u2:Usuario)
WITH u1, count(u2) as salida
SET u1.cantNodosSalida = salida

MATCH (u1:Usuario)-->(u2:Usuario)
WITH u2, count(u1) as entrada
SET u2.cantNodosEntrada = entrada

MATCH (u1:Usuario)
RETURN u1.cantNodosSalida, count(u1)

MATCH (u1:Usuario)
RETURN u1.cantNodosEntrada, count(u1)
```
Result:
Sin Indice:

 - Promedio: 
 - Varianza: 

Con Indice "CREATE INDEX ON :Usuario(idNoticia)":

 - Promedio: 
 - Varianza: 

5)
```
MATCH (user:Usuario)
WITH count(distinct(user)) as total
MATCH (root:Usuario)-[:INFECTA]->()
WHERE NOT ()-[:INFECTA]->(root) 
RETURN count(distinct(root))*100/total as proporcion
```

Result:
Sin Indice:

 - Promedio: 7,3
 - Varianza: 3,61

Con Indice "CREATE INDEX ON :Usuario(screemname)":

 - Promedio: 5,9
 - Varianza: 0,29

## Conclusión

 Este trabajo nos permitió indagar un poco sobre este nuevo tipo de base de datos no sql. Algunas ventajas que pudimos observar de la misma es que reflejan perfectamente la relación entre distintas entidades, permitiendo así, realizar analisis más profundos sobre relaciones. Un ejemplo para mostrar esto es el del [tutorial de neo4j sobre fraudes](https://neo4j.com/graphgists/?category=fraud-detection), o mismo, este trabajo practico, donde analizamos el impacto de las noticias en base a twitts (donde los usuarios eran las entidades y los rettuits las relaciones).
 
  Por otro lado, algo un poco negativo de la misma es que es un paradigma totalmente distinto al de sql y hace que la curva de aprendizaje sea mayor (sobre todo si nunca trabajaste sobre grafos). Sin embargo, las consultas nos resultaron más declarativas que SQL.
  
  En síntesis, es una base de datos muy interesante para determinados casos donde las consultas sobre relaciones son fundamentales, pero si la intension es solo almacenar información (sin darle tanta importancia a las relaciones) es mejor seleccionar otro tipo de base de datos no sql (basada en documentos, por ejemplo).
  
  En cuanto al análisis de los datos, pudimos dar cuenta de la gran penetración que tienen algunos usuarios sobre la comunidad de las redes sociales. Quedo claro, en nuestro analisis, que son pocos los usuarios que se encargan de dinfundir masivamente noticias falsas.
  Los resultados arrojaron que tan solo una única noticia logro penetrar a más del 25%, dando a entender que para esta muestra de datos en esta comunidad, no parece ser el caso en donde la cobertura de cada noticia abarque a la mayoría. Tampoco parece ser común el hecho de que un usuario esté en contacto con mas del 20% de las noticias, ya que se hayó un único caso.

