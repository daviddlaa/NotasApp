const { PNG } = require('pngjs');
const fs = require('fs');

function createIcon(path, size, isBackground) {
  var png = new PNG({ width: size, height: size });
  var cx = size / 2;
  var cy = size / 2;
  
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var idx = (size * y + x) << 2;
      
      if (isBackground) {
        // Fondo blanco/crema para el icono principal
        png.data[idx] = 255;
        png.data[idx+1] = 250;
        png.data[idx+2] = 240;
        png.data[idx+3] = 255;
      } else {
        // Diseño de Cuaderno/Journal
        var relX = x / size;
        var relY = y / size;
        
        var inIcon = false;
        
        // Color del cuaderno: azul/morado oscuro
        var r = 106, g = 90, b = 205; // SlateBlue
        
        // Marco del cuaderno (rectángulo principal)
        if (relX >= 0.20 && relX <= 0.80 && relY >= 0.12 && relY <= 0.88) {
          inIcon = true;
        }
        
        // Binding/spiral en el lado izquierdo (líneas verticales)
        if (relX >= 0.20 && relX <= 0.26 && relY >= 0.15 && relY <= 0.85) {
          inIcon = true;
          // Color más oscuro para el binding
          r = 75; g = 0; b = 130;
        }
        
        // Espiral (círculos pequeños)
        var spiralY = [0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80];
        for (var i = 0; i < spiralY.length; i++) {
          var sy = spiralY[i];
          var dist = Math.sqrt(Math.pow(relX - 0.23, 2) + Math.pow(relY - sy, 2));
          if (dist < 0.035) {
            inIcon = true;
            r = 200; g = 200; b = 200; // Gris plata para espiral
          }
        }
        
        // Líneas horizontales de contenido (líneas de papel)
        var linePositions = [0.30, 0.40, 0.50, 0.60, 0.70, 0.80];
        for (var i = 0; i < linePositions.length; i++) {
          var ly = linePositions[i];
          if (relX >= 0.32 && relX <= 0.74 && relY >= ly - 0.015 && relY <= ly + 0.015) {
            inIcon = true;
            r = 200; g = 200; b = 220; // Gris claro para líneas
          }
        }
        
        // Título del cuaderno (rectángulo rojo en superior)
        if (relX >= 0.35 && relX <= 0.65 && relY >= 0.18 && relY <= 0.24) {
          inIcon = true;
          r = 220; g = 60; b = 60; // Rojo oscuro
        }
        
        if (inIcon) {
          png.data[idx] = r;
          png.data[idx+1] = g;
          png.data[idx+2] = b;
          png.data[idx+3] = 255;
        } else {
          png.data[idx] = 0;
          png.data[idx+1] = 0;
          png.data[idx+2] = 0;
          png.data[idx+3] = 0;
        }
      }
    }
  }
  
  fs.writeFileSync(path, PNG.sync.write(png));
  console.log('Created ' + path);
}

// Create foreground icon (cuaderno)
createIcon('c:/Users/david/Desktop/notas/notas/notas/assets/icon_foreground.png', 512, false);

// Create background for adaptive icon
createIcon('c:/Users/david/Desktop/notas/notas/notas/assets/icon.png', 512, true);

// Also create for Android
createIcon('c:/Users/david/Desktop/notas/notas/notas/android/app/src/main/res/drawable/ic_launcher_background.png', 512, true);
