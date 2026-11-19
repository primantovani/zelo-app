package br.com.zelo.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "APOIO_OCORRENCIA")
public class ApoioOcorrencia {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_APOIO")
    private Long id;
    @Column(name = "ID_USUARIO", nullable = false) private Long idUsuario;
    @Column(name = "ID_OCORRENCIA", nullable = false) private Long idOcorrencia;
    @Column(name = "TIPO_APOIO", nullable = false) private String tipoApoio;
    @Column(name = "DATA_APOIO") private LocalDateTime dataApoio;
    public Long getId(){return id;} public Long getIdUsuario(){return idUsuario;}
    public Long getIdOcorrencia(){return idOcorrencia;} public String getTipoApoio(){return tipoApoio;}
    public LocalDateTime getDataApoio(){return dataApoio;}
    public void setIdUsuario(Long v){idUsuario=v;} public void setIdOcorrencia(Long v){idOcorrencia=v;}
    public void setTipoApoio(String v){tipoApoio=v;}
}
