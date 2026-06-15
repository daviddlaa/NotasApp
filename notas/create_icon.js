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
        // Diseño moderno: "N" estilizada en amarillo dorado
        var relX = x / size;
        var relY = y / size;
        
        // Fondo transparente
        var inIcon = false;
        
        // Barra vertical izquierda de la N
        if (relX >= 0.22 && relX <= 0.32 && relY >= 0.18 && relY <= 0.82) {
          inIcon = true;
        }
        
        // Barra diagonal de la N
        var diagDist = Math.abs((relY - 0.18) - 2.5 * (relX - 0.22));
        if (relX >= 0.30 && relX <= 0.50 && relY >= 0.18 && relY <= 0.82 && diagDist < 0.08) {
          inIcon = true;
        }
        
        // Barra vertical derecha de la N
        if (relX >= 0.68 && relX <= 0.78 && relY >= 0.18 && relY <= 0.82) {
          inIcon = true;
        }
        
        // Líneas horizontales simulando texto (debajo de la N)
        if (relY >= 0.55 && relY <= 0.60 && relX >= 0.35 && relX <= 0.65) {
          inIcon = true;
        }
        if (relY >= 0.65 && relY <= 0.70 && relX >= 0.35 && relX <= 0.55) {
          inIcon = true;
        }
        
        if (inIcon) {
          png.data[idx] = 255;
          png.data[idx+1] = 193;
          png.data[idx+2] = 7;
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

// Create foreground icon (the N design)
createIcon('c:/Users/david/Desktop/notas/notas/notas/assets/icon_foreground.png', 512, false);

// Create background for adaptive icon
createIcon('c:/Users/david/Desktop/notas/notas/notas/assets/icon.png', 512, true);

// Also create for Android
createIcon('c:/Users/david/Desktop/notas/notas/notas/android/app/src/main/res/drawable/ic_launcher_background.png', 512, true);
