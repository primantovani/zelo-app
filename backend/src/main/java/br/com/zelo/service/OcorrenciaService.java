package br.com.zelo.service;

import br.com.zelo.dto.ApiDtos.*;
import br.com.zelo.domain.*;
import br.com.zelo.repository.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.sql.Types;
import java.util.List;

@Service
public class OcorrenciaService {
    private final JdbcTemplate jdbc; private final OcorrenciaRepository ocorrencias;
    private final FotoOcorrenciaRepository fotos; private final ApoioOcorrenciaRepository apoios;
    private final UsuarioRepository usuarios;
    public OcorrenciaService(JdbcTemplate jdbc, OcorrenciaRepository ocorrencias, FotoOcorrenciaRepository fotos,
       ApoioOcorrenciaRepository apoios, UsuarioRepository usuarios) {
        this.jdbc=jdbc;this.ocorrencias=ocorrencias;this.fotos=fotos;this.apoios=apoios;this.usuarios=usuarios;
    }
    @Transactional
    public OcorrenciaCriadaResponse criar(CriarOcorrenciaRequest r) {
        final Long[] id={null}; final String[] protocolo={null};
        jdbc.execute(con -> {
            var cs=con.prepareCall("{call PRC_REGISTRAR_OCORRENCIA(?,?,?,?,?,?,?,?,?)}");
            cs.setLong(1,r.idUsuario()); cs.setLong(2,r.idCategoria()); cs.setString(3,r.titulo());
            cs.setString(4,r.descricao()); cs.setDouble(5,r.latitude()); cs.setDouble(6,r.longitude());
            cs.setString(7,r.endereco()); cs.registerOutParameter(8,Types.NUMERIC); cs.registerOutParameter(9,Types.VARCHAR);
            return cs;
        }, cs -> {cs.execute(); id[0]=cs.getLong(8); protocolo[0]=cs.getString(9); return null;});
        return new OcorrenciaCriadaResponse(id[0],protocolo[0],"Ocorrência registrada com sucesso.");
    }
    @Transactional(readOnly=true) public List<Ocorrencia> listar(){return ocorrencias.findAll();}
    @Transactional(readOnly=true) public Ocorrencia buscar(Long id){return ocorrencias.findById(id).orElseThrow(()->new IllegalArgumentException("Ocorrência não encontrada."));}
    @Transactional(readOnly=true) public List<Ocorrencia> minhas(Long idUsuario){return ocorrencias.findByIdUsuario(idUsuario);}
    @Transactional(readOnly=true) public Ocorrencia porProtocolo(String protocolo){return ocorrencias.findByProtocolo(protocolo).orElseThrow(()->new IllegalArgumentException("Protocolo não encontrado."));}
    @Transactional public void alterarStatus(Long id, AlterarStatusRequest r) {
        jdbc.update(con -> {
            var cs=con.prepareCall("{call PRC_ALTERAR_STATUS(?,?,?,?)}");
            cs.setLong(1,id); cs.setLong(2,r.idUsuario()); cs.setString(3,r.novoStatus());
            if(r.observacao()==null) cs.setNull(4,Types.VARCHAR); else cs.setString(4,r.observacao());
            return cs;
        }, cs -> {cs.execute(); return null;});
    }
    @Transactional public FotoOcorrencia adicionarFoto(Long id, FotoRequest r) {
        buscar(id); FotoOcorrencia f=new FotoOcorrencia(); f.setIdOcorrencia(id); f.setUrlFoto(r.urlFoto()); return fotos.save(f);
    }
    @Transactional(readOnly=true) public List<FotoOcorrencia> listarFotos(Long id){buscar(id);return fotos.findByIdOcorrencia(id);}
    @Transactional public ApoioOcorrencia apoiar(Long id, ApoioRequest r) {
        buscar(id);
        if(!usuarios.existsById(r.idUsuario())) throw new IllegalArgumentException("Usuário não encontrado.");
        if(apoios.existsByIdUsuarioAndIdOcorrencia(r.idUsuario(),id)) throw new IllegalArgumentException("Este usuário já apoiou esta ocorrência.");
        String tipo=r.tipoApoio().toUpperCase();
        if(!tipo.equals("APOIO") && !tipo.equals("CONFIRMACAO")) throw new IllegalArgumentException("Tipo deve ser APOIO ou CONFIRMACAO.");
        ApoioOcorrencia a=new ApoioOcorrencia();a.setIdUsuario(r.idUsuario());a.setIdOcorrencia(id);a.setTipoApoio(tipo);return apoios.save(a);
    }
    @Transactional(readOnly=true) public List<ApoioOcorrencia> listarApoios(Long id){buscar(id);return apoios.findByIdOcorrencia(id);}
}
