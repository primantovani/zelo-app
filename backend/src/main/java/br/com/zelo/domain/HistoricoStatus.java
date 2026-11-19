package br.com.zelo.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "HISTORICO_STATUS")
public class HistoricoStatus {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_HISTORICO")
    private Long id;
    @Column(name = "ID_OCORRENCIA", nullable = false) private Long idOcorrencia;
    @Column(name = "ID_USUARIO", nullable = false) private Long idUsuario;
    @Column(name = "STATUS_ANTERIOR") private String statusAnterior;
    @Column(name = "STATUS_NOVO", nullable = false) private String statusNovo;
    @Column(name = "OBSERVACAO") private String observacao;
    @Column(name = "DATA_ALTERACAO") private LocalDateTime dataAlteracao;
    public Long getId(){return id;} public Long getIdOcorrencia(){return idOcorrencia;}
    public Long getIdUsuario(){return idUsuario;} public String getStatusAnterior(){return statusAnterior;}
    public String getStatusNovo(){return statusNovo;} public String getObservacao(){return observacao;}
    public LocalDateTime getDataAlteracao(){return dataAlteracao;}
}
