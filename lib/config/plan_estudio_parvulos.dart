class ItemPlanEstudio {
  const ItemPlanEstudio({
    required this.ingles,
    this.pronunciacion,
    this.espanol,
    this.tema,
    this.soloIngles = false,
  });

  final String ingles;
  final String? pronunciacion;
  final String? espanol;
  final String? tema;
  final bool soloIngles;

  String get id => '${tema ?? ''}::$ingles';
}

class CategoriaPlanEstudio {
  const CategoriaPlanEstudio({required this.nombre, required this.items});

  final String nombre;
  final List<ItemPlanEstudio> items;
}

class PeriodoPlanEstudio {
  const PeriodoPlanEstudio({required this.numero, required this.categorias});

  final int numero;
  final List<CategoriaPlanEstudio> categorias;
}

const planEstudioParvulos = <int, PeriodoPlanEstudio>{
  1: PeriodoPlanEstudio(
    numero: 1,
    categorias: [
      CategoriaPlanEstudio(
        nombre: 'Commands',
        items: [
          ItemPlanEstudio(
            ingles: 'Good morning',
            pronunciacion: 'gud morning',
            espanol: 'Buenos días',
          ),
          ItemPlanEstudio(
            ingles: 'Sit down',
            pronunciacion: 'sit daun',
            espanol: 'Sentarse',
          ),
          ItemPlanEstudio(
            ingles: 'Stand up',
            pronunciacion: 'stand ap',
            espanol: 'De pie',
          ),
        ],
      ),
      CategoriaPlanEstudio(
        nombre: 'Songs',
        items: [ItemPlanEstudio(ingles: 'Hello song')],
      ),
      CategoriaPlanEstudio(
        nombre: 'Vocabulary',
        items: [
          ItemPlanEstudio(ingles: 'Colors', espanol: 'Colores'),
          ItemPlanEstudio(
            ingles: 'Yellow',
            pronunciacion: 'iélou',
            espanol: 'Amarillo',
          ),
          ItemPlanEstudio(
            ingles: 'Blue',
            pronunciacion: 'blu',
            espanol: 'Azul',
          ),
          ItemPlanEstudio(ingles: 'Red', pronunciacion: 'red', espanol: 'Rojo'),
          ItemPlanEstudio(
            ingles: 'Green',
            pronunciacion: 'griin',
            espanol: 'Verde',
          ),
          ItemPlanEstudio(ingles: 'My body', espanol: 'Mi cuerpo'),
          ItemPlanEstudio(ingles: 'Boy', pronunciacion: 'boi', espanol: 'Niño'),
          ItemPlanEstudio(
            ingles: 'Girl',
            pronunciacion: 'guerl',
            espanol: 'Niña',
          ),
          ItemPlanEstudio(ingles: 'My family', espanol: 'Mi familia'),
          ItemPlanEstudio(ingles: 'Mother / Mom', espanol: 'Mamá'),
          ItemPlanEstudio(ingles: 'Father / Dad', espanol: 'Papá'),
          ItemPlanEstudio(ingles: 'Baby', espanol: 'Bebé'),
          ItemPlanEstudio(ingles: 'Sister', espanol: 'Hermana'),
          ItemPlanEstudio(ingles: 'Brother', espanol: 'Hermano'),
        ],
      ),
    ],
  ),
  2: PeriodoPlanEstudio(
    numero: 2,
    categorias: [
      CategoriaPlanEstudio(
        nombre: 'Commands',
        items: [
          ItemPlanEstudio(ingles: 'Make a line', espanol: 'Hagan la fila'),
          ItemPlanEstudio(ingles: 'Hands up', espanol: 'Manos arriba'),
          ItemPlanEstudio(ingles: 'Hands down', espanol: 'Manos abajo'),
        ],
      ),
      CategoriaPlanEstudio(
        nombre: 'Songs',
        items: [ItemPlanEstudio(ingles: 'Hello dear teacher')],
      ),
      CategoriaPlanEstudio(
        nombre: 'Vocabulary',
        items: [
          ItemPlanEstudio(ingles: 'Opposites', espanol: 'Opuestos'),
          ItemPlanEstudio(ingles: 'Small', espanol: 'Pequeño'),
          ItemPlanEstudio(ingles: 'Big', espanol: 'Grande'),
          ItemPlanEstudio(ingles: 'Up', espanol: 'Arriba'),
          ItemPlanEstudio(ingles: 'Down', espanol: 'Abajo'),
          ItemPlanEstudio(ingles: 'Professions', espanol: 'Profesiones'),
          ItemPlanEstudio(ingles: 'Teacher', espanol: 'Profesor(a)'),
          ItemPlanEstudio(ingles: 'Nurse', espanol: 'Enfermera'),
          ItemPlanEstudio(ingles: 'Doctor', espanol: 'Doctor'),
          ItemPlanEstudio(ingles: 'Animals', espanol: 'Animales'),
          ItemPlanEstudio(ingles: 'Chicken', espanol: 'Pollito'),
          ItemPlanEstudio(ingles: 'Hen', espanol: 'Gallina'),
          ItemPlanEstudio(ingles: 'Dog', espanol: 'Perro'),
          ItemPlanEstudio(ingles: 'Cat', espanol: 'Gato'),
          ItemPlanEstudio(ingles: 'Wild animals', espanol: 'Animales salvajes'),
          ItemPlanEstudio(ingles: 'Lion', espanol: 'León'),
          ItemPlanEstudio(ingles: 'Elephant', espanol: 'Elefante'),
          ItemPlanEstudio(ingles: 'Giraffe', espanol: 'Jirafa'),
        ],
      ),
    ],
  ),
  3: PeriodoPlanEstudio(
    numero: 3,
    categorias: [
      CategoriaPlanEstudio(
        nombre: 'Commands',
        items: [
          ItemPlanEstudio(ingles: 'Bye bye', espanol: 'Adiós'),
          ItemPlanEstudio(ingles: 'Come here', espanol: 'Ven aquí'),
          ItemPlanEstudio(
            ingles: 'Have you finished?',
            espanol: '¿Terminaste?',
          ),
        ],
      ),
      CategoriaPlanEstudio(
        nombre: 'Songs',
        items: [ItemPlanEstudio(ingles: 'Make a circle')],
      ),
      CategoriaPlanEstudio(
        nombre: 'Vocabulary',
        items: [
          ItemPlanEstudio(
            ingles: 'Means of transportation',
            espanol: 'Medios de transporte',
          ),
          ItemPlanEstudio(ingles: 'Car', espanol: 'Carro'),
          ItemPlanEstudio(ingles: 'Ship', espanol: 'Barco'),
          ItemPlanEstudio(ingles: 'Airplane', espanol: 'Avión'),
          ItemPlanEstudio(ingles: 'Emotions', espanol: 'Emociones'),
          ItemPlanEstudio(ingles: 'Happy', espanol: 'Feliz'),
          ItemPlanEstudio(ingles: 'Sad', espanol: 'Triste'),
          ItemPlanEstudio(ingles: 'Angry', espanol: 'Enojado'),
          ItemPlanEstudio(ingles: 'Scared', espanol: 'Asustado'),
          ItemPlanEstudio(ingles: 'Classroom', espanol: 'Salón de clase'),
          ItemPlanEstudio(ingles: 'Book', espanol: 'Libro'),
          ItemPlanEstudio(ingles: 'Crayon', espanol: 'Crayola'),
          ItemPlanEstudio(ingles: 'Colors', espanol: 'Colores'),
        ],
      ),
    ],
  ),
  4: PeriodoPlanEstudio(
    numero: 4,
    categorias: [
      CategoriaPlanEstudio(
        nombre: 'Commands',
        items: [
          ItemPlanEstudio(ingles: 'Go to the yard', espanol: 'Ve al patio'),
          ItemPlanEstudio(ingles: 'Hello teacher', espanol: 'Hola profesor'),
          ItemPlanEstudio(
            ingles: 'Come into the classroom',
            espanol: 'Entra al salón',
          ),
        ],
      ),
      CategoriaPlanEstudio(
        nombre: 'Songs',
        items: [
          ItemPlanEstudio(ingles: 'Hello song'),
          ItemPlanEstudio(ingles: 'Make a circle'),
          ItemPlanEstudio(ingles: 'Hello dear teacher'),
        ],
      ),
      CategoriaPlanEstudio(
        nombre: 'Vocabulary',
        items: [
          ItemPlanEstudio(ingles: 'The fruits', espanol: 'Las frutas'),
          ItemPlanEstudio(ingles: 'Banana', espanol: 'Banano'),
          ItemPlanEstudio(ingles: 'Pear', espanol: 'Pera'),
          ItemPlanEstudio(ingles: 'Apple', espanol: 'Manzana'),
          ItemPlanEstudio(ingles: 'Grapes', espanol: 'Uvas'),
          ItemPlanEstudio(ingles: 'Orange', espanol: 'Naranja'),
          ItemPlanEstudio(ingles: 'The numbers', espanol: 'Los números'),
          ItemPlanEstudio(ingles: 'One', espanol: 'Uno'),
          ItemPlanEstudio(ingles: 'Two', espanol: 'Dos'),
          ItemPlanEstudio(ingles: 'Three', espanol: 'Tres'),
          ItemPlanEstudio(ingles: 'Four', espanol: 'Cuatro'),
          ItemPlanEstudio(ingles: 'Five', espanol: 'Cinco'),
          ItemPlanEstudio(ingles: 'Clothes', espanol: 'Prendas de vestir'),
          ItemPlanEstudio(ingles: 'Shirt', espanol: 'Camisa'),
          ItemPlanEstudio(ingles: 'Dress', espanol: 'Vestido'),
          ItemPlanEstudio(ingles: 'Pants', espanol: 'Pantalones'),
          ItemPlanEstudio(ingles: 'Shoes', espanol: 'Zapatos'),
        ],
      ),
    ],
  ),
};
