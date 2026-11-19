package br.com.zelo.repository;
import br.com.zelo.domain.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface CategoriaRepository extends JpaRepository<Categoria, Long> {
    List<Categoria> findByAtivo(String ativo);
}
