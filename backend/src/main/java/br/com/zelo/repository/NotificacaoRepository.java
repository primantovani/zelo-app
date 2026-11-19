package br.com.zelo.repository;
import br.com.zelo.domain.Notificacao;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface NotificacaoRepository extends JpaRepository<Notificacao, Long> {
    List<Notificacao> findByIdUsuarioOrderByDataEnvioDesc(Long idUsuario);
}
