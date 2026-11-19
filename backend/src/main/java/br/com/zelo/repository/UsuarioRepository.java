package br.com.zelo.repository;
import br.com.zelo.domain.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByEmail(String email);
}
