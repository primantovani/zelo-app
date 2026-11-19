package br.com.zelo.repository;
import br.com.zelo.domain.ApoioOcorrencia;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface ApoioOcorrenciaRepository extends JpaRepository<ApoioOcorrencia, Long> {
    List<ApoioOcorrencia> findByIdOcorrencia(Long idOcorrencia); boolean existsByIdUsuarioAndIdOcorrencia(Long idUsuario, Long idOcorrencia);
}
