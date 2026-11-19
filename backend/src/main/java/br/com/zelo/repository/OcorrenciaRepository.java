package br.com.zelo.repository;
import br.com.zelo.domain.Ocorrencia;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface OcorrenciaRepository extends JpaRepository<Ocorrencia, Long> {
    List<Ocorrencia> findByIdUsuario(Long idUsuario); Optional<Ocorrencia> findByProtocolo(String protocolo);
}
