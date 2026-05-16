package com.GAV.gav.Config;

import com.GAV.gav.Model.Lugar;
import com.GAV.gav.Repository.LugarRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

// Siembra el catálogo de lugares de Cartagena de Indias si la tabla está vacía.
// Idempotente: solo inserta si lugarRepository.count() == 0.
@Component
@Order(1)
@RequiredArgsConstructor
public class LugarSeeder implements CommandLineRunner {

    private final LugarRepository lugarRepository;

    @Override
    public void run(String... args) {
        if (lugarRepository.count() > 0) {
            return;
        }

        List<Lugar> lugares = List.of(
            lugar("Castillo San Felipe de Barajas", Lugar.Categoria.ZONA_HISTORICA,
                "Fortaleza colonial más grande construida por los españoles en América.",
                "historia, fortaleza, turismo, mirador, colonial",
                "10.4226", "-75.5390", 250),
            lugar("Ciudad Amurallada (Centro Histórico)", Lugar.Categoria.ZONA_HISTORICA,
                "Casco antiguo amurallado, Patrimonio de la Humanidad.",
                "historia, murallas, turismo, colonial, plazas, caminata",
                "10.4236", "-75.5510", 400),
            lugar("Torre del Reloj", Lugar.Categoria.ZONA_HISTORICA,
                "Puerta principal de la ciudad amurallada.",
                "historia, monumento, turismo, foto",
                "10.4225", "-75.5510", 150),
            lugar("Playa de Bocagrande", Lugar.Categoria.PLAYA,
                "Playa urbana rodeada de hoteles y restaurantes.",
                "playa, mar, sol, hoteles, turismo",
                "10.4000", "-75.5550", 500),
            lugar("Playa Blanca (Barú)", Lugar.Categoria.PLAYA,
                "Playa de arena blanca y aguas turquesa en Barú.",
                "playa, mar, arena blanca, paradisiaco, turismo",
                "10.1700", "-75.6500", 600),
            lugar("Aeropuerto Internacional Rafael Núñez", Lugar.Categoria.AEROPUERTO,
                "Aeropuerto principal de Cartagena, en el barrio Crespo.",
                "aeropuerto, vuelos, viaje, terminal aérea",
                "10.4424", "-75.5130", 300),
            lugar("Mall Plaza El Castillo", Lugar.Categoria.MALL,
                "Centro comercial cerca del Castillo San Felipe.",
                "compras, tiendas, comida, cine, mall",
                "10.4218", "-75.5403", 200),
            lugar("Centro Comercial Caribe Plaza", Lugar.Categoria.MALL,
                "Centro comercial con tiendas, cine y restaurantes.",
                "compras, tiendas, ropa, cine, comida, mall",
                "10.4090", "-75.5360", 200),
            lugar("Centro Comercial La Serrezuela", Lugar.Categoria.MALL,
                "Mall de lujo en el centro histórico.",
                "compras, marcas, lujo, restaurantes, cine, mall",
                "10.4257", "-75.5494", 180),
            lugar("Getsemaní", Lugar.Categoria.ZONA_HISTORICA,
                "Barrio bohemio con arte callejero y vida nocturna.",
                "bohemio, arte, murales, vida nocturna, bares, gastronomia",
                "10.4200", "-75.5450", 300),
            lugar("Las Bóvedas", Lugar.Categoria.ZONA_HISTORICA,
                "Antiguas mazmorras hoy mercado de artesanías.",
                "artesanias, souvenirs, compras, historia",
                "10.4280", "-75.5500", 120),
            lugar("Convento de la Popa", Lugar.Categoria.MUSEO,
                "Convento en el cerro más alto, vista panorámica.",
                "mirador, historia, religioso, vista, turismo",
                "10.4180", "-75.5290", 200),
            lugar("Museo del Oro Zenú", Lugar.Categoria.MUSEO,
                "Museo con orfebrería de la cultura Zenú.",
                "museo, cultura, oro, historia, arte",
                "10.4237", "-75.5512", 100),
            lugar("Plaza Santo Domingo", Lugar.Categoria.ZONA_HISTORICA,
                "Plaza icónica con la escultura de Botero.",
                "plaza, botero, restaurantes, turismo, foto",
                "10.4244", "-75.5515", 120),
            lugar("Restaurante La Cevichería", Lugar.Categoria.RESTAURANTE,
                "Reconocido por sus ceviches y mariscos.",
                "mariscos, comida de mar, ceviche, pescado, gourmet",
                "10.4270", "-75.5490", 80),
            lugar("Restaurante Carmen", Lugar.Categoria.RESTAURANTE,
                "Alta cocina contemporánea colombiana.",
                "gourmet, alta cocina, fine dining, contemporaneo",
                "10.4255", "-75.5495", 80),
            lugar("Café del Mar", Lugar.Categoria.BAR,
                "Bar sobre las murallas con vista al atardecer.",
                "bar, atardecer, copas, vista al mar, murallas",
                "10.4248", "-75.5530", 100),
            lugar("Parque Centenario", Lugar.Categoria.PARQUE,
                "Parque urbano con fauna local junto a Getsemaní.",
                "parque, naturaleza, paseo, familia",
                "10.4210", "-75.5460", 150),
            lugar("Muelle de la Bodeguita (Islas del Rosario)", Lugar.Categoria.PARQUE,
                "Punto de embarque hacia las Islas del Rosario y el Acuario.",
                "islas, tours, snorkel, mar, acuario, lancha",
                "10.4215", "-75.5505", 120),
            lugar("Hotel Las Américas", Lugar.Categoria.HOTEL,
                "Complejo hotelero en la zona norte (Cielo Mar).",
                "hotel, resort, playa, eventos, alojamiento",
                "10.4540", "-75.5050", 300),
            lugar("Playa de Castillogrande", Lugar.Categoria.PLAYA,
                "Playa tranquila en zona residencial exclusiva.",
                "playa, tranquilo, residencial, mar",
                "10.3950", "-75.5600", 350),
            lugar("Barrio Crespo", Lugar.Categoria.OTRO,
                "Zona cercana al aeropuerto, hoteles y residencias.",
                "aeropuerto, hoteles, residencial",
                "10.4400", "-75.5160", 400)
        );

        lugarRepository.saveAll(lugares);
    }

    private Lugar lugar(String nombre, Lugar.Categoria categoria, String descripcion,
                        String etiquetas, String lat, String lng, int radio) {
        return new Lugar(null, nombre, categoria, descripcion, etiquetas,
                new BigDecimal(lat), new BigDecimal(lng), radio, true);
    }
}
