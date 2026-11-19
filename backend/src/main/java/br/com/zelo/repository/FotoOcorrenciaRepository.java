package br.com.zelo.repository;
import br.com.zelo.domain.FotoOcorrencia;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface FotoOcorrenciaRepository extends JpaRepository<FotoOcorrencia, Long> {
    List<FotoOcorrencia> findByIdOcorrencia(Long idOcorrencia);
}
