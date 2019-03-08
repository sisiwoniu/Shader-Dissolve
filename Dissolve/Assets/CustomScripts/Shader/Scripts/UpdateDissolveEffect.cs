using System.Collections;
using UnityEngine;

public class UpdateDissolveEffect : MonoBehaviour {

    [SerializeField]
    private Color NoiseColor;

    [SerializeField, Range(0f, 1f)]
    private float DefaultThreshold = 1f;

#if UNITY_EDITOR
    public bool Debug = true;
#endif

    private readonly int ThresholdID = Shader.PropertyToID("_Threshold");

    private readonly int NoiseColorID = Shader.PropertyToID("_NoiseColor");

    private IEnumerator changeThresholdIEnumeator;

    private MaterialPropertyBlock materialBlock;

    private Renderer s_renderer;

    public void ChangeThreshold(float Value, float Dur) {
        Value = Mathf.Clamp(Value, 0f, 1f);

        if(changeThresholdIEnumeator != null)
            StopCoroutine(changeThresholdIEnumeator);

        changeThresholdIEnumeator = ChangeThresholdIE(Value, Dur);

        StartCoroutine(changeThresholdIEnumeator);
    }

    public void PauseAnim() {
        if(changeThresholdIEnumeator != null)
            StopCoroutine(changeThresholdIEnumeator);
    }

    public void ResumeAnim() {
        if(changeThresholdIEnumeator != null)
            StartCoroutine(changeThresholdIEnumeator);
    }

    private void LateUpdate() {
#if UNITY_EDITOR
        if(Debug) {
            if(Input.GetKeyDown(KeyCode.A))
                ChangeThreshold(1f, 1f);
            else if(Input.GetKeyDown(KeyCode.B))
                ChangeThreshold(0f, 1f);
        }
#endif

        s_renderer.SetPropertyBlock(materialBlock);
    }

    private void Start() {
        s_renderer = GetComponent<Renderer>();

        if(s_renderer == null)
            enabled = false;

        materialBlock = new MaterialPropertyBlock();

        s_renderer.GetPropertyBlock(materialBlock);

        materialBlock.SetColor(NoiseColorID, NoiseColor);

        materialBlock.SetFloat(ThresholdID, DefaultThreshold);
    }

    private IEnumerator ChangeThresholdIE(float Value, float Dur) {

        var startValue = materialBlock.GetFloat(ThresholdID);

        float timeCache = 0f;

        while(timeCache < Dur) {
            timeCache += Time.deltaTime;

            var nowValue = Mathf.Lerp(startValue, Value, Mathf.Clamp(timeCache / Dur, 0f, 1f));

            materialBlock.SetFloat(ThresholdID, nowValue);

            yield return null;
        }

        //実行時間が0の場合強制代入する
        materialBlock.SetFloat(ThresholdID, Value);

        changeThresholdIEnumeator = null;
    }
}
