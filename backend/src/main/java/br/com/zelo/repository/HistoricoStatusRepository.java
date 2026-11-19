package br.com.zelo.repository;
import br.com.zelo.domain.HistoricoStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface HistoricoStatusRepository extends JpaRepository<HistoricoStatus, Long> {
    List<HistoricoStatus> findByIdOcorrenciaOrderByDataAlteracaoAsc(Long idOcorrencia);
}
