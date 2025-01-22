/**
 ** Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
 ** Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 **/
package  mushop;

import io.micronaut.runtime.Micronaut;
import jakarta.inject.Singleton;

@Singleton
public class Application {
        public static void main(String[] args) {
            Micronaut.build(args)
            .packages("mushop")  // 明示的にパッケージを指定
            .mainClass(Application.class)
            .start();
        }
    }