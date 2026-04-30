package com.GAV.gav;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

// NUEVO: @EnableScheduling activa el scheduler de Spring que ejecuta el método
// ViajeService.verificarSolicitudesExpiradas() cada 10 segundos para avanzar el FIFO
// cuando un conductor no responde a tiempo.
@SpringBootApplication
@EnableScheduling
public class GavApplication {

	public static void main(String[] args) {
		SpringApplication.run(GavApplication.class, args);
	}
}
