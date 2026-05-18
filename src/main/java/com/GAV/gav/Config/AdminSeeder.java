package com.GAV.gav.Config;

import com.GAV.gav.Model.Rol;
import com.GAV.gav.Model.Usuario;
import com.GAV.gav.Repository.RolRepository;
import com.GAV.gav.Repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.text.SimpleDateFormat;

// Siembra un usuario ADMIN por defecto si NO existe ninguno.
// Sin esto, un despliegue limpio no tiene forma de entrar como administrador
// ni de registrar conductores (solo el admin puede), bloqueando todo el panel.
// Idempotente: si ya hay un admin, no toca nada.
// Credenciales configurables por properties (NO hardcodeadas como secreto):
//   admin.seed.username / admin.seed.password / admin.seed.email
// Debe correr DESPUÉS de RolSeeder (@Order(0)) y TarifaSeeder (@Order(1)).
@Slf4j
@Component
@Order(2)
@RequiredArgsConstructor
public class AdminSeeder implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${admin.seed.username:admin}")
    private String adminUsername;

    @Value("${admin.seed.password:admin123}")
    private String adminPassword;

    @Value("${admin.seed.email:admin@gav.com}")
    private String adminEmail;

    @Override
    public void run(String... args) throws Exception {
        Rol rolAdmin = rolRepository.findByNombre("ROLE_ADMIN").orElse(null);
        if (rolAdmin == null) {
            log.warn("[AdminSeeder] ROLE_ADMIN no existe aún; se omite (revisar RolSeeder).");
            return;
        }

        if (usuarioRepository.findByNombreUsuario(adminUsername).isPresent()) {
            log.info("[AdminSeeder] El admin '{}' ya existe, nada que insertar.", adminUsername);
            return;
        }

        Usuario admin = new Usuario();
        admin.setNombreCompleto("Administrador");
        admin.setApellidosCompletos("GAV");
        admin.setFechaNacimiento(new SimpleDateFormat("yyyy-MM-dd").parse("1990-01-01"));
        admin.setNombreUsuario(adminUsername);
        admin.setContrasena(passwordEncoder.encode(adminPassword));
        admin.setTelefono("3000000000");
        admin.setTipoDocumento(Usuario.TipoDocumento.CC);
        admin.setNumeroDocumento("0000000000");
        admin.setEmail(adminEmail);
        admin.setRol(rolAdmin);

        usuarioRepository.save(admin);
        log.info("[AdminSeeder] Admin por defecto creado: usuario='{}' (cambia la contraseña en producción).",
                adminUsername);
    }
}
