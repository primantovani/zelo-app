package br.com.zelo.service;
import br.com.zelo.domain.*;
import br.com.zelo.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class ConsultaService {
    private final CategoriaRepository categorias; private final HistoricoStatusRepository historicos;
    private final NotificacaoRepository notificacoes;
    public ConsultaService(CategoriaRepository c, HistoricoStatusRepository h, NotificacaoRepository n){categorias=c;historicos=h;notificacoes=n;}
    public List<Categoria> categorias(){return categorias.findByAtivo("S");}
    public List<HistoricoStatus> historico(Long id){return historicos.findByIdOcorrenciaOrderByDataAlteracaoAsc(id);}
    public List<Notificacao> notificacoes(Long idUsuario){return notificacoes.findByIdUsuarioOrderByDataEnvioDesc(idUsuario);}
    @Transactional public Notificacao marcarLida(Long id){Notificacao n=notificacoes.findById(id).orElseThrow(()->new IllegalArgumentException("Notificação não encontrada."));n.setLida("S");return notificacoes.save(n);}
}
